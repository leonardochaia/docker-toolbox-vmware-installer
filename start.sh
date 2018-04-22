#!/bin/bash

trap '[ "$?" -eq 0 ] || read -p "Looks like something went wrong in step ´$STEP´... Press any key to continue..."' EXIT

VM=${DOCKER_MACHINE_NAME-default}
DOCKER_MACHINE=./docker-machine.exe

BLUE='\033[1;34m'
GREEN='\033[0;32m'
NC='\033[0m'


if [ ! -f "${DOCKER_MACHINE}" ]; then
  echo "Docker Machine is not installed. Please re-run the Toolbox Installer and try again."
  exit 1
fi

"C:/Program Files (x86)/VMware/VMware Workstation/vmrun.exe" list | grep \""${VM}"\" &> /dev/null
VM_EXISTS_CODE=$?

set -e

STEP="Checking if machine $VM exists"
if [ $VM_EXISTS_CODE -eq 1 ]; then
  STEP="Machine $VM exists. Creating Proxies"  
  #set proxy variables if they exists
  if [ -n ${HTTP_PROXY+x} ]; then
    PROXY_ENV="$PROXY_ENV --engine-env HTTP_PROXY=$HTTP_PROXY"
  fi
  if [ -n ${HTTPS_PROXY+x} ]; then
    PROXY_ENV="$PROXY_ENV --engine-env HTTPS_PROXY=$HTTPS_PROXY"
  fi
  if [ -n ${NO_PROXY+x} ]; then
    PROXY_ENV="$PROXY_ENV --engine-env NO_PROXY=$NO_PROXY"
  fi  
else
  STEP="Machine $VM does not exist. Creating Docker Machine"  
  "${DOCKER_MACHINE}" create -d vmwareworkstation $PROXY_ENV --vmwareworkstation-disk-size 102400 --vmwareworkstation-memory-size 2048 "${VM}"
fi

STEP="Checking status on $VM"
VM_STATUS="$(${DOCKER_MACHINE} status ${VM} 2>&1)"
if [ "${VM_STATUS}" != "Running" ]; then
  "${DOCKER_MACHINE}" start "${VM}"
  yes | "${DOCKER_MACHINE}" regenerate-certs "${VM}"
fi

STEP="Setting env for current session"
eval "$(${DOCKER_MACHINE} env --shell=bash ${VM})"

STEP="Finalize"
clear
cat << EOF


                        ##         .
                  ## ## ##        ==
               ## ## ## ## ##    ===
           /"""""""""""""""""\___/ ===
      ~~~ {~~ ~~~~ ~~~ ~~~~ ~~~ ~ /  ===- ~~~
           \______ o           __/
             \    \         __/
              \____\_______/

EOF
echo -e "${BLUE}docker${NC} is configured to use the ${GREEN}${VM}${NC} machine with IP ${GREEN}$(${DOCKER_MACHINE} ip ${VM})${NC}"
echo "For help getting started, check out the docs at https://docs.docker.com"
echo
echo "You can use docker commands in this shell. To use in PowerShell run 'docker-machine env | Invoke-Expression'"
cd

docker () {
  MSYS_NO_PATHCONV=1 docker.exe "$@"
}
export -f docker

if [ $# -eq 0 ]; then
  echo "Start interactive shell"
  exec "$BASH" --login -i
else
  echo "Start shell with command"
  exec "$BASH" -c "$*"
fi