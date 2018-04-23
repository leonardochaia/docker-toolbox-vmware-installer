# VMWare DockerToolbox PowerShell Installer
This script aims to help in the installation of the VMWare Driver pecigonzalo/docker-machine-vmwareworkstation
for Docker Machine.

Usage: `PS > ./install.ps1 -diskSize 102400 -memory 2048`
It will:
- If needed, downloads and install DockerToolbox with Docker and DockerMachine only
- If needed, downloads and install pecigonzalo/docker-machine-vmwareworkstation
- Create a Docker Machine with the provided disk size and memory.
- Create a Start Menu Shortcut
- Propmt to configure Docker Machine Auto start
