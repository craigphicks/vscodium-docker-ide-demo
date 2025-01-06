
# Developing with VSCodium in Isolated Docker Container Environments

## Abstract

This document is a "how to" for implementing an Integrated Development Environment (IDE) using VSCodium and Docker containers.  It is a viable alternative to an IDE based on proprietary VSCode with the proprietary Devcontainers extension.


## Introduction

VSCodium (colloquially "codium") is the open source version of Microsofts freely available, but private, soure code editor VSCode.  

With respect to licensing and telemetry they differ as follows:

- VSCode includes Microsoft-specific customizations, branding, and telemetry (user data collection).
- VSCodium strips out Microsoft's telemetry and branding, providing a fully open-source version with no data collection.

With respect to extensions:

- VSCode includes a large "Marketplace" of VSCode extensions, including many provided by Microsoft.  Those MS extensions often depend on proprietary interface features present in VSCode, but not present in VSCodium.   

- While VSCodium can access all the extensions in the VSCode extension Marketplace, the extensions which depend on proprietary interface features present in VSCode will not work, and must rely on free alternatives instead.

For example, the popular "Dev Containers" extension available in "VSCode" cannot be used in "VSCodium".  The good news is that development containers can be implemented without using the extension "Dev Containers". In fact the simplicity and transparency of doing so makes it even better than "Dev Containers".  

1. Prepare a Docker container with your required development libraries and the ability to run an ssh server.

2. Connect to the docker container from VSCodium using an ssh based extension. 

3. The IDE is complete and you may edit source and run code inside the Docker container from VSCodium.


## Setup

### Software components 

This setup was performed on Debian12 running GNOME desktop.  It should be mostly applicable to any Debian based Linux such as Ubuntu.

The software components to be installed are:

- docker-compose
    - installation
        - `sudo apt install docker-compose`
- flatpak 
    - installation
        - `sudo apt install flatpak`
        - If using Gnome Desktop GUI add flatpak to the application tray with
            - `sudo apt install gnome-software-plugin-flatpak`
    - configure
        - `flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo`
        - add the following to `~/.bashrc`
            - `XDG_DATA_DIRS=$XDG_DATA_DIRS:/home/craig/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share`
            - `PATH=/usr/local/sbin/:$PATH:/var/lib/flatpak/exports/bin`
- vscodium
    - installation
        - `flatpak --user install flathub com.vscodium.codium`
- "Open Remote" [Author: jeanp413] is a vscodium extension selected from the vscodium extension menu.

*Note 1: VSCodium can be installed in other ways besides using flatpak.*
*Note 2: VSCodium under flatpak is itself running in an isolated container.  However that container will not be used at all for the IDE.  The container used for the IDE will be a Docker container to be connected via ssh.*


### SSH Config

Add the following section to your host `~/.ssh.config` file:

```
Host mydev
    HostName 127.0.0.1
    User root
    Port 20202
    IdentityFile ~/.ssh/id_devcontainer
    StrictHostKeyChecking no
```

This section describes the ssh interface to be used for the Docker container.

The entry `StrictHostKeyChecking no` prevents warning when the containers own identifying key changes.  That will happen whenever the container image is rebuilt.


### Directory structure

Create the following directory structure

```text
- ~/
  - codium-ide-demo/
     - .docker.d/
```

`codium-ide-demo` will be the working directory of the IDE.

`.docker.d` is the *docker build context directory*, containing the Dockerfile.  This directory is included under the IDE working directory because it includes the development library specs, etc.  (Although those are omitted in this demo.)  

### variables bash file

Create a bash file with the variables which will be used

`~/codium-ide-demo/.docker.d/variable.sh`
```bash

```


### build-run bash file

Create a bash file `~/codium-ide-demo/.docker.d/build-run.sh` with the following contents:


`~/codium-ide-demo/.docker.d/build-run.sh`
```bash

```

Make it executable.
```
chmod +x ~/codium-ide-demo/.docker.d/build-run.sh
```


### Docker file

For the sake of simplicity, the Dockerfile shown here does not include any software for development purposes.  It includes only the bare minimum Dockerfile code to enable VSCodium to connect to the Docker container.  

`~/codium-ide-demo/.docker.d/Dockerfile`
```

```


## Execute

Change directory to the *docker build context directory*.

```
cd ~/codium-ide-demo/.docker.d
```

Run the `build-run.sh` script (optionally saving the results in a log file).
```
build-run.sh 2>1& | tee build.log 
```

If `build_run` complete's successfully, a VSCodium window will pop up.  

Click on either `Connect to ...` or the blue connection symbol on the bottom left corner.  A menu will pop up - select "*Connect current window to host*".

A box will popup with a heading "*Enter [user@]hostname[:port]*".  You only need to enter `mydev` and hit return.

The blue box in the bottom left hand corner should now say "*ssh: mydev*"

Open the */work/* folder. The contents should be the IDE view of the `~/codium-ide-demo` folder on the host.  However, the container environment is decided by the IDE's dockerfile.

## Discussion

This setup was not developed and tested for the case where the Docker container is built and run on an external machine, so some modifications would be required for that scenario.

A sample Dockerfile as shown here, but also including an IDE with conda, miniforge, python, numpy, and pytorch, is available [here]().

[This blog "Develop in Containers with VSCodium" by David Sebek]() was a useful reference while developing this system.

