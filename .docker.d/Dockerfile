####################################################################
# Specific to customized IDE 
####################################################################

FROM ubuntu:latest

#################################################################
# Below here specific to running Docker container connected to VSCodium
#################################################################
USER root
ARG USERNAME=root

# Install OpenSSH server and sudo
RUN apt-get update && apt-get install -y openssh-server sudo
# Create the privilege separation directory and set permissions
RUN mkdir -p /run/sshd && chmod 0755 /run/sshd
# Add configurations to the sshd_config file
RUN echo "Port 22" >> /etc/ssh/sshd_config && \
    echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
# Define the ARG variable for the key file name
ARG ONE_TIME_PASSWD=secret
RUN echo "$USERNAME:${ONE_TIME_PASSWD}" | chpasswd;
# Expose the SSH port
EXPOSE 22


############ Workaround so the VSCODE terminals (inside the container) ############
############ have the correct environment (E.g., PATH)                 ############

# Save the build time environment variables to a file `buildtime_env`.
# Some variables are ommitted
RUN env | grep -v -E "^(SHLVL|ONE_TIME_PASSWD|PWD|HOME|HOMEDIR)=" > /${USERNAME}/buildtime_env

# Add some code to `~/.bashrc` which will read the content of `buildtime_env` 
# and add those variables into the current shell environment.

RUN echo "if [ ! -z \"\${VSCODE_IPC_HOOK_CLI}\" ] && [ -t 0 ]; then" >> /${USERNAME}/.bashrc && \
    echo "  while IFS='=' read -r key value; do" >> /${USERNAME}/.bashrc && \
    echo "    if [[ \$key =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] && [[ \$value =~ ^[[:print:]]*$ ]]; then" >> /${USERNAME}/.bashrc && \
    echo "      export \"\$key=\$value\"" >> /${USERNAME}/.bashrc && \
    echo "    fi" >> /${USERNAME}/.bashrc && \
    echo "  done < /${USERNAME}/buildtime_env" >> /${USERNAME}/.bashrc && \
    echo "fi" >> /${USERNAME}/.bashrc

# The condition `[ ! -z \"\${VSCODE_IPC_HOOK_CLI}\" ] && [ -t 0 ]` says:
#   If VSCODE_IPC_HOOK_CLI is defined in the current enviroment 
#   and stdin is a TTY

# Issue filed: https://github.com/jeanp413/open-remote-ssh/issues/186
############ End of Workaround                                         ############

# enable saving history on mounted directory even if container is rebuilt
ARG MOUNT_CONT_DIR=/work/
RUN echo "HISTFILE=${MOUNT_CONT_DIR}.bash_history" >> /${USERNAME}/.bashrc
RUN echo "PROMPT_COMMAND=\"history -a; history -c; history -r; \$PROMPT_COMMAND\"" >> /${USERNAME}/.bashrc
# Start the SSH service
CMD ["/usr/sbin/sshd", "-D"]

