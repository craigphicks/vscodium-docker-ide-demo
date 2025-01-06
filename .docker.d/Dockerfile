FROM ubuntu:latest


#################
# Add development environment installation here
#################

# Install OpenSSH server and sudo
RUN apt-get update && apt-get install -y openssh-server sudo

# Create the privilege separation directory and set permissions
RUN mkdir -p /run/sshd && chmod 0755 /run/sshd

# Add configurations to the sshd_config file
RUN echo "Port 22" >> /etc/ssh/sshd_config && \
    echo "PermitRootLogin yes" >> /etc/ssh/sshd_config

# Define the ARG variable for the key file name
ARG PASSWD=secret

RUN echo "root:${PASSWD}" | chpasswd;

# Expose the SSH port
EXPOSE 22

ARG MOUNT_CONT_DIR=/work/

# save history between sessions
#RUN echo "alias hig=\"history | grep\"" >> ${MOUNT_CONT_DIR}.bashrc
RUN echo "HISTFILE=${MOUNT_CONT_DIR}.bash_history" >> /root/.bashrc
RUN echo "PROMPT_COMMAND=\"history -a; history -c; history -r; \$PROMPT_COMMAND\"" >> /root/.bashrc

# Start the SSH service
CMD ["/usr/sbin/sshd", "-D"]