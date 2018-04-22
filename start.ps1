# Script inspired from original Docker VMWare driver start.sh
# https://github.com/pecigonzalo/docker-machine-vmwareworkstation
# It's done in PowerShell so that a Linux Bash is not required.

$dockerToolboxRoot = Join-Path $env:programfiles "Docker Toolbox\"

if (![System.IO.File]::Exists((Join-Path $dockerToolboxRoot "docker-machine.exe"))) {
    Write-Host "DockerToolbox is not installed. Re run the install.ps1 script" -ForegroundColor Red
    Exit
}

$machineName = "default"
Write-Host "Starting Docker Machine $machineName"
docker-machine start $machineName

Write-Host "Setting Docker env for current session"
docker-machine env $machineName | Invoke-Expression
#Clear-Host

Write-Host '
                        ##         .
                  ## ## ##        ==
               ## ## ## ## ##    ===
           /"""""""""""""""""\___/ ===
      ~~~ {~~ ~~~~ ~~~ ~~~~ ~~~ ~ /  ===- ~~~
           \______ o           __/
             \    \         __/
              \____\_______/

'
$dockerIp = docker-machine ip $machineName
Write-Host
Write-Host "Docker is configured to use the $machineName with IP $dockerIp" -ForegroundColor Yellow
Write-Host
Write-Host "You can run Docker commands in this shell." -ForegroundColor Yellow
Write-Host "For other PowerShells firs run 'docker-machine env $machineName | Invoke-Expression'"
Write-Host "So that the shell is configured to work with this Docker Machine"
