#!/bin/bash
# Function to check the exit status of a command and return if it's non-zero
check_exit_status() {
  if [ $1 -ne 0 ]; then
    echo "Error: $2 failed with exit code $1"
    return $1
  else 
    echo ":) $2 passed" 
  fi
}
source ./variables.sh

docker build -t ${DIMAGE_NAME}:latest --build-arg PASSWD=${PASSWD} --build-arg MOUNT_CONT_DIR=${MOUNT_CONT_DIR} .
check_exit_status $? "docker build" || return $?

# Remove existing container if it exists
if [ "$(docker ps -aq -f name=${DCONT_NAME})" ]; then
    echo "Container ${DCONT_NAME} already exists. Stopping and removing it..."
    docker rm -f ${DCONT_NAME}
    check_exit_status $? "docker rm" || return $?
fi

docker run -d -p ${SSH_CONFIG_HOST_PORT}:22 -v ${MOUNT_HOST_DIR}:${MOUNT_CONT_DIR} --name ${DCONT_NAME} ${DIMAGE_NAME}
check_exit_status $? "docker run" || return $?

# Check if the key file already exists
if [ -f "${KEY_FILE_PATH}" ]; then
    echo "The SSH key ${KEY_FILE_PATH} already exists. Skipping key generation."
else
    echo "The SSH key ${KEY_FILE_PATH} does not exist. Generating a new key..."
    ssh-keygen -t ed25519 -f "${KEY_FILE_PATH}" -C "dev@example.com" -N "${KEY_PASSPHRASE}"
    res=$?
    if [ $res -ne 0 ]; then 
        rm -f "${KEY_FILE_PATH}"
        rm -f "${KEY_FILE_PATH}.pub"
    fi
    check_exit_status $res "ssh-keygen" || return $res
fi

sshpass -p ${PASSWD} ssh-copy-id mydev
check_exit_status $? "sshpass | ssh-copy-id" || return $?

echo exit | ssh mydev
check_exit_status $? "echo exit | ssh mydev" || return $?

docker exec -it ${DCONT_NAME} /bin/bash -c "passwd -dl root"
check_exit_status $? "docker exec passwd" || return $?

echo "flatpak --user run --cwd=\"${MOUNT_HOST_DIR}\" com.vscodium.codium"
flatpak --user --cwd=${MOUNT_HOST_DIR} run com.vscodium.codium 




