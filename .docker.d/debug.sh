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

KEY_FILE_PATH="$HOME/.ssh/id_ed25519.pub"
PASSWD="secret"
DIMAGE_NAME="mydev_image"
DCONT_NAME="mydev"
HOST_PORT=20202
HOST_DIR=$(pwd)/..
CONT_DIR="/work/"

docker build -t ${DIMAGE_NAME}:latest --build-arg PASSWD=${PASSWD} .
check_exit_status $? "docker build" || return $?

# Remove existing container if it exists
if [ "$(docker ps -aq -f name=${DCONT_NAME})" ]; then
    echo "Container ${DCONT_NAME} already exists. Stopping and removing it..."
    docker rm -f ${DCONT_NAME}
    check_exit_status $? "docker rm" || return $?
fi

docker run -d -p ${HOST_PORT}:22 -v ${HOST_DIR}:${CONT_DIR} --name ${DCONT_NAME} ${DIMAGE_NAME}
check_exit_status $? "docker run" || return $?

ssh-keygen -f "${HOME}/.ssh/known_hosts" -R "[localhost]:${HOST_PORT}"
check_exit_status $? "ssh-keygen" || return $?

sshpass -p ${PASSWD} ssh-copy-id -i ${KEY_FILE_PATH} -p ${HOST_PORT} root@localhost
echo "sshpass/ssh-copy-id returned $?"

# Check and set correct permissions for SSH keys inside the container
docker exec -it ${DCONT_NAME} /bin/bash -c "chmod 700 /root/.ssh && chmod 600 /root/.ssh/authorized_keys && chown -R root:root /root/.ssh"
check_exit_status $? "docker exec set key permissions" || return $?

# Verify SSH daemon configuration
docker exec -it ${DCONT_NAME} /bin/bash -c "grep -i 'PermitRootLogin yes' /etc/ssh/sshd_config"
check_exit_status $? "docker exec check PermitRootLogin" || return $?
docker exec -it ${DCONT_NAME} /bin/bash -c "grep -i 'PasswordAuthentication no' /etc/ssh/sshd_config"
check_exit_status $? "docker exec check PasswordAuthentication" || return $?
docker exec -it ${DCONT_NAME} /bin/bash -c "grep -i 'PubkeyAuthentication yes' /etc/ssh/sshd_config"
check_exit_status $? "docker exec check PubkeyAuthentication" || return $?

# Restart SSH daemon
docker exec -it ${DCONT_NAME} /bin/bash -c "service ssh restart"
check_exit_status $? "docker exec restart ssh" || return $?

# Setting root password to be deleted and locked
docker exec -it ${DCONT_NAME} /bin/bash -c "passwd -dl root"
check_exit_status $? "docker exec passwd" || return $?

# Connect to Docker container via SSH
ssh -o StrictHostKeyChecking=no -i ${KEY_FILE_PATH} -p ${HOST_PORT} root@localhost
echo "ssh returned $?"
