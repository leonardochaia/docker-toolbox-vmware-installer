param (
    [int]$diskSize = 102400,
    [int]$memory = 2048
)

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { 
    # Run as administrator
    $params = ""
    foreach ($boundparam in $PSBoundParameters.GetEnumerator()) {
        $params += "-{0} {1} " -f $boundparam.Key, $boundparam.Value
    }
    Start-Process powershell.exe "-ExecutionPolicy Bypass -NoExit -File `"$PSCommandPath`" $params" -Verb RunAs; 
    Exit 
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;

# Install DockerToolbox
$dockerToolboxRoot = Join-Path $env:programfiles "Docker Toolbox\"
if (![System.IO.File]::Exists((Join-Path $dockerToolboxRoot "docker-machine.exe"))) {
    $toolboxTempPath = "$PSScriptRoot/tmp/DockerToolbox.exe";
    if (![System.IO.File]::Exists($toolboxTempPath)) {
        Write-Host "Downloading DockerToolbox.."
        Invoke-WebRequest -Uri "https://download.docker.com/win/stable/DockerToolbox.exe" -OutFile $toolboxTempPath
    }

    Write-Host "Installing DockerToolbox"
    ./DockerToolbox.exe /COMPONENTS="Docker,DockerMachine"
}
else {
    Write-Host "DockerToolbox seems to be already installed."
}

# Get Docker VMWare Driver
$driverFile = "docker-machine-driver-vmwareworkstation.exe"
if (![System.IO.File]::Exists((Join-Path $dockerToolboxRoot $driverFile))) {
    
    $dockerMachineVmwarePath = "$PSScriptRoot/tmp/docker-machine-driver-vmwareworkstation.exe";
    if (![System.IO.File]::Exists($dockerMachineVmwarePath)) {
        $repo = "pecigonzalo/docker-machine-vmwareworkstation"
        $releases = "https://api.github.com/repos/$repo/releases"
    
        Write-Host "Downloading $driverFile.."
        $tag = (Invoke-WebRequest $releases | ConvertFrom-Json)[0].tag_name
        $download = "https://github.com/$repo/releases/download/$tag/$driverFile"

        Invoke-WebRequest -Uri $download -OutFile $dockerMachineVmwarePath
    }

    Write-Host "Copying VMWare driver to DockerToolbox root.."
    Copy-Item -Path $dockerMachineVmwarePath -Destination $dockerToolboxRoot -Force; 
}

# Copy start files
Write-Host "Copying start scripts to DockerToolbox root.."
$newStartPath = Join-Path $PSScriptRoot "start.sh"
$newStartPathPs = Join-Path $PSScriptRoot "start.ps1"
Copy-Item -Path $newStartPath -Destination $dockerToolboxRoot -Force; 
Copy-Item -Path $newStartPathPs -Destination $dockerToolboxRoot -Force;

# Create Docker Machine if nessesary
$dockerMachineName = "default"
$machineExists = docker-machine inspect $dockerMachineName
if ($machineExists) {
    Write-Host "Found Docker Machine named [$dockerMachineName]. No Docker Machine will be created."
}
else {
    Write-Host "Creating VMWare Docker Machine with 100gb Disk Size and 2gb RAM.." -ForegroundColor Yellow
    docker-machine create --driver vmwareworkstation --vmwareworkstation-disk-size $diskSize --vmwareworkstation-memory-size $memory $dockerMachineName
}

# Create Start Menu Shortcut
$shortcutName = "Docker QuickStart PowerShell.lnk"
$shortCutPath = Join-Path $env:USERPROFILE "\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Docker\$shortcutName"
if (![System.IO.File]::Exists($shortCutPath)) {
    Write-Host "Generating Start Menu Shortcut"
    $wshShell = New-Object -comObject WScript.Shell
    $shortcut = $wshShell.CreateShortcut($shortCutPath)
    $shortcut.TargetPath = 'powershell.exe'
    $shortcutScriptPath = Join-Path $dockerToolboxRoot "/start.ps1"
    $shortcut.Arguments = "-NoExit -File `"$shortcutScriptPath`""
    $shortcut.WorkingDirectory = $dockerToolboxRoot
    $shortcut.IconLocation = "%SystemDrive%\Program Files\Docker Toolbox/docker-quickstart-terminal.ico"
    $shortcut.Save()
}

$autoStartPath = Join-Path $env:USERPROFILE "\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"
if (![System.IO.File]::Exists((Join-Path $autoStartPath $shortcutName ))) {
    $confirmation = Read-Host "Start Docker Machine (VMWare VM) on windows startup? [y/n]"
    if ($confirmation -eq 'y') {
        Write-Host "Generating Windows Auto Start"
        Copy-Item -Path $shortCutPath -Destination $autoStartPath -Force; 
    }
}

Write-Host
Write-Host

Write-Host "You can get a configured Docker Shell by opening 'Docker QuickStart Powershell' from Windows startup menu" -ForegroundColor Yellow

Write-Host
Write-Host

& $newStartPathPs