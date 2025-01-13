#!/bin/bash
# Function to check the exit status of a command and exit if it's non-zero
check_exit_status() {
  if [ $1 -ne 0 ]; then
    echo "Error: $2 failed with exit code $1"
    return $1
  else 
    echo ":) $2 passed" 
  fi
}

read_ssh_config_values() {
  local section_name=$1
  local config_file="$HOME/.ssh/config"

  # Check if the config file exists
  if [[ ! -f "$config_file" ]]; then
    echo "SSH config file not found at $config_file"
    return 1
  fi

  # Read the entries for the given host
  awk -v section="$section_name" '
    $1 == "Host" {
      in_host_block = ($2 == section)
      next
    }
    in_host_block {
      if ($1 == "HostName") hostname = $2
      else if ($1 == "Port") port = $2
      else if ($1 == "IdentityFile") identityfile = $2
      else if ($1 == "User") username = $2
    }
    END {
      print hostname, port, identityfile, username
    }
  ' "$config_file"
}

ONE_TIME_PASSWD=""
NO_BUILD=0



# Check for the --no-build argument
while [ $# -gt 0 ]; do
  case "$1" in
    --no-build)
      NO_BUILD=1
      shift
      ;;
    *)
      # Default case: if no pattern matches
      ONE_TIME_PASSWD=$1
      shift
      break
      ;;
  esac
done

if [ $# -gt 0 ]; then
  echo "unexpected extra arguments $#" 
  exit 1
fi

# Check if ONE_TIME_PASSWD is empty after processing arguments
if [ -z "$ONE_TIME_PASSWD" ]; then
  echo "Error: Expecting value for ONE_TIME_PASSWD, and it cannot be an empty string"
  exit 1
fi

source ./variables.sh

# Call the function and capture the output into a variable
output=$(read_ssh_config_values "${DCONT_NAME}")
echo $output

# Parse the output into variables
read -r SSH_CONFIG_HOST_NAME SSH_CONFIG_HOST_PORT KEY_FILE_PATH CONT_USERNAME <<< "$output"
# Transform the identityfile variable if it starts with "~"
if [[ $KEY_FILE_PATH == "~"* ]]; then
  KEY_FILE_PATH="${HOME}${KEY_FILE_PATH:1}"
fi


# Print the values to verify
echo "Values read from ~/.ssh/config entry ${DCONT_NAME}:"
echo "    HostName: $SSH_CONFIG_HOST_NAME"
echo "    Port: $SSH_CONFIG_HOST_PORT"
echo "    IdentityFile: $KEY_FILE_PATH"
echo "    User: $CONT_USERNAME"


# Print a message if NO_BUILD is 1
if [ "$NO_BUILD" -eq 1 ]; then
  echo "NO_BUILD is set to 1. Skipping the build step."
else 
  # Build the Docker image
  echo \#\# docker build -t ${DIMAGE_NAME} --build-arg ONE_TIME_PASSWD=${ONE_TIME_PASSWD} --build-arg MOUNT_CONT_DIR=${MOUNT_CONT_DIR} .
  docker build -t ${DIMAGE_NAME} --build-arg ONE_TIME_PASSWD=${ONE_TIME_PASSWD} --build-arg MOUNT_CONT_DIR=${MOUNT_CONT_DIR} .
  check_exit_status $? "docker build" || exit $?

fi

# Remove existing container if it exists
if [ "$(docker ps -aq -f name=${DCONT_NAME})" ]; then
    echo "Container ${DCONT_NAME} already exists. Stopping and removing it..."
    docker rm -f ${DCONT_NAME}
    check_exit_status $? "docker rm" || exit $?
fi

# Run the container
echo \#\# docker run -d -p ${SSH_CONFIG_HOST_NAME}:${SSH_CONFIG_HOST_PORT}:22 -v ${MOUNT_HOST_DIR}:${MOUNT_CONT_DIR} --name ${DCONT_NAME} ${DIMAGE_NAME}
docker run -d -p ${SSH_CONFIG_HOST_NAME}:${SSH_CONFIG_HOST_PORT}:22 -v ${MOUNT_HOST_DIR}:${MOUNT_CONT_DIR} --name ${DCONT_NAME} ${DIMAGE_NAME}
check_exit_status $? "docker run" || exit $?

# Check if the key file already exists.  If not, generate a new key.
if [ -f "${KEY_FILE_PATH}" ]; then
    echo "The SSH key ${KEY_FILE_PATH} already exists. Skipping key generation."
else
    echo "The SSH key ${KEY_FILE_PATH} does not exist. Generating a new key..."
    # Note the key has no passphrase.
    echo \#\# ssh-keygen -t ed25519 -f "${KEY_FILE_PATH}" -C "dev@example.com" -N ""
    ssh-keygen -t ed25519 -f "${KEY_FILE_PATH}" -C "dev@example.com" -N ""
    res=$?
    if [ $res -ne 0 ]; then 
        rm -f "${KEY_FILE_PATH}"
        rm -f "${KEY_FILE_PATH}.pub"
    fi
    check_exit_status $res "ssh-keygen" || exit $res
fi

# Remove existing entries for [${SSH_CONFIG_HOST_NAME}]:${SSH_CONFIG_HOST_NAME}
# from ~/.ssh/known_hosts
echo \#\# ssh-keygen -f ~/.ssh/known_hosts -R [${SSH_CONFIG_HOST_NAME}]:${SSH_CONFIG_HOST_PORT}
ssh-keygen -f ~/.ssh/known_hosts -R "[${SSH_CONFIG_HOST_NAME}]:${SSH_CONFIG_HOST_PORT}"
check_exit_status $? "use ssh-keygen to remove entries from known_hosts" || exit $?

# Add the key to the authorized_keys file on the container
# Note: ssh-copy-id requires explictly specifying the key file path with -i to prevent ssh from using the default key.
echo \#\# sshpass -p ${ONE_TIME_PASSWD} ssh-copy-id f -i ${KEY_FILE_PATH} ${DCONT_NAME}
sshpass -p ${ONE_TIME_PASSWD} ssh-copy-id -f -i ${KEY_FILE_PATH} ${DCONT_NAME}
res=$?
if [ $res -ne 0 ]; then
    echo "sshpass \| ssh-copy-id" failed but try one more time.  Sometimes it just works!
    sleep 1
    echo \#\# sshpass -p ${ONE_TIME_PASSWD} ssh-copy-id f -i ${KEY_FILE_PATH} ${DCONT_NAME}
    sshpass -p ${ONE_TIME_PASSWD} ssh-copy-id -f -i ${KEY_FILE_PATH} ${DCONT_NAME}
    check_exit_status $? "sshpass \| ssh-copy-id" || exit $?
fi

# Test the SSH connection
echo \#\# echo exit \| ssh ${DCONT_NAME}
echo exit | ssh ${DCONT_NAME}
check_exit_status $? "echo exit \| ssh ${DCONT_NAME}" || exit $?

# Remove the root password
echo \#\# docker exec -it ${DCONT_NAME} /bin/bash -c "passwd -dl root"
docker exec -it ${DCONT_NAME} /bin/bash -c "passwd -dl root"
check_exit_status $? "docker exec passwd" || exit $?





