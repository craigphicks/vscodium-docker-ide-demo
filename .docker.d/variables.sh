PASSWD="secret"
DIMAGE_NAME="mydev_image"
DCONT_NAME="mydev"
MOUNT_HOST_DIR=/home/craig/github/codium-test
MOUNT_CONT_DIR="/work/"
DOCKER_BUILD_CONTEXT_DIR=${MOUNT_HOST_DIR}/.docker.d
# If this key passphrase is NOT empty, then the 
# bash script build-run.sh will fail because of 
# unexpected prompts will appear asking  for the 
# key passphrase
KEY_PASSPHRASE=""
# KEY_FILE_PATH must be value given in  
#   ~/.ssh/config for Host ${DCONT_NAME} -  IdentityFile
KEY_FILE_PATH="$HOME/.ssh/id_devcontainer"
# SSH_CONFIG_HOST_PORT must be value given in  
#   ~/.ssh/config for Host ${DCONT_NAME} -  Port
SSH_CONFIG_HOST_PORT=20202
# HOST_Name must be value given in  
#   ~/.ssh/config for Host ${DCONT_NAME} -  HostName
SSH_CONFIG_HOST_NAME=127.0.0.1
