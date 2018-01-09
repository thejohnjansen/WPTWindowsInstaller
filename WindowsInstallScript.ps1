#########################################################################
# Set execution policy for running the installations
#########################################################################
Write-Host
Write-Host "Setting Execution Policy to install from SSL"
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Unrestricted
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Write-Host

#########################################################################
# Global variables - change these as necessary
#########################################################################
$systemDrive = $env:SystemDrive.ToLower()
$pythonTarget = "$systemDrive\python27"
$toolsTarget = "$systemDrive\tools"
$driverTarget = "$systemDrive\drivers"
$gitTarget = $env:ProgramFiles.ToLower()
$documentsFolder = [Environment]::GetFolderPath("MyDocuments").ToLower()
$repoTarget = "$documentsFolder\github\web-platform-tests"
$buildType = "insiders"

#########################################################################
# Install Choices - You can turn some of these off 
# since you probably already have them
#########################################################################
$InstallChocolatey = $true
$InstallPython = $true
$InstallGit = $true
$InstallPip = $true
$EnableVirtualEnv = $true
$InstallTestRepo = $true
$InstallDrivers = $true
$SetPathVar = $true
$InstallHosts = $true
$InstallAhem = $true
$RunTests = $true

#########################################################################
# Create the directories as needed
#########################################################################
if (!(Test-Path $toolsTarget)) {
    mkdir $toolsTarget
}

if (!(Test-Path $driverTarget)) {
    mkdir $driverTarget
}

#########################################################################
# Add necessary directories to the Path variable - 
# you can change this to "User" instead of "Machine" if you like
#########################################################################
$pathString = [environment]::GetEnvironmentVariable("Path", "Machine")
$newPaths = $null

if ($SetPathVar) {
    if (!($pathString.Contains("$pythonTarget"))) {
        Write-Host "Adding Python to the path"
        $newPaths += "$pythonTarget;"        
    }

    if (!($pathString.Contains("$pythonTarget\scripts"))) {
        Write-Host "Adding Python Scripts to the path"
        $newPaths += "$pythonTarget\scripts;"        
    }

    if (!($pathString.Contains("$gitTarget"))) {
        Write-Host "Adding Git to the path"
        $newPaths += "$gitTarget\git\cmd;"
    }

    if (!($pathString.Contains("$driverTarget"))) {
        Write-Host "Adding Drivers to the path"
        $newPaths += "$driverTarget;"
    }
    
    if (!($pathString.Contains("$toolsTarget"))) {
        Write-Host "Adding Tools to the path"
        $newPaths += "$toolsTarget;"
    }

    if ($newPaths) {
        [Environment]::SetEnvironmentVariable("Path", "$newPaths" + "$Env:Path", "Machine")
        Write-Host "Path variable set"
    }
    else {
        Write-Host "Looks like all PATH variables were already set. Not setting them."
    }
}
else {
    Write-Host "Not setting the Path"
}

RefreshEnv
Start-Sleep -Seconds 15
Write-Host

#########################################################################
# Install Chocolatey
#########################################################################
if ($InstallChocolatey) {
    Write-Host "Installing Chocolatey..."
    Invoke-Expression ((new-object net.webclient).DownloadString(
        'https://chocolatey.org/install.ps1'))
    Write-Host "Chocolately Installed"
}
else {
    Write-Host "Not Installing Chocolatey."
}
Write-Host

#########################################################################
# Install Python using Chocolatey
#########################################################################
if ($InstallPython) {
    Write-Host "Installing python"
    cinst python2 -y -o -ia "'/qn /norestart ALLUSERS=1 TARGETDIR=$pythonTarget'"
    Write-Host "Python Installed"
}
else {
    Write-Host "Not installing python"
}
Write-Host

#########################################################################
# Install git using Chocolatey
#########################################################################
if ($InstallGit) {
    Write-Host "Installing git"
    cinst git -y
    Write-Host "Git Installed"
}
else {
    Write-Host "Not installing git"
}
Write-Host

#########################################################################
# Install Pip
#########################################################################
if ($InstallPip) {
    Write-Host "Installing Pip"
    $pipDest = "$pythonTarget\get-pip.py"

    (new-object net.webclient).DownloadFile('https://bootstrap.pypa.io/get-pip.py',$pipDest)
    python $pythonTarget\get-pip.py
    Write-Host "Pip Installed"
}
else {
    Write-Host "Not installing Pip"
}
Write-Host

#########################################################################
# Install VirtualEnv
#########################################################################

If ($EnableVirtualEnv) {
    Write-Host "Enabling virtualenv"
    pip install virtualenv
    Write-Host "Virtualenv Installed"
}
else {
    Write-Host "Not enabling virualenv"
}
Write-Host

#########################################################################
# Get the Web Platform Tests Repo
#########################################################################
if ($InstallTestRepo) {
    Write-Host "Getting the test repo"
    git clone "https://github.com/w3c/web-platform-tests.git" $repoTarget
    Write-Host "Test Repo Installed"
}
else {
    Write-Host "Not getting the test repo"
}
Write-Host

#########################################################################
# Get WebDriver(s) and put them in c:\drivers
#########################################################################
if ($InstallDrivers) {
    Write-Host "Getting the drivers"
    # ChromeDriver
    (new-object net.webclient).DownloadFile(
        "https://chromedriver.storage.googleapis.com/2.34/chromedriver_win32.zip",
        "$toolsTarget\chromedriver.zip")

    $zipPackage = (new-object -com shell.application).Namespace("$toolsTarget\chromedriver.zip")
    $destinationFolder = (new-object -com shell.application).Namespace($driverTarget)
    $destinationFolder.CopyHere($zipPackage.Items(),0x14)
    Write-Host "ChromeDriver Installed"

    # MicrosoftWebDriver
    $mwdVersion = "D/4/1/D417998A-58EE-4EFE-A7CC-39EF9E020768"

    if ($buildType = "insiders") {
        $mwdVersion = "1/4/1/14156DA0-D40F-460A-B14D-1B264CA081A5"
    }

    $url = "https://download.microsoft.com/download/$mwdVersion/MicrosoftWebDriver.exe"
    $dest = "$driverTarget\MicrosoftWebDriver.exe"

    (new-object net.webclient).DownloadFile($url,$dest)
    Write-Host "MicrosoftWebDriver Installed"
}
else {
    Write-Host "Not getting the drivers"
}
Write-Host

#########################################################################
# Set necessary values in HOSTS file
#########################################################################
if ($InstallHosts) {
    Write-Host "Setting the HOSTS file"
    $wordToFind="web-platform.test"
    $hostsLocation = "$env:SystemRoot\System32\drivers\etc\hosts"

    $file = Get-Content $hostsLocation
    $containsWord = $file | %{$_ -match $wordToFind}

# if the file already contains web-platform.test, don't do anything
    If(!($containsWord -contains $true)) {
        $newString = New-Object -TypeName "System.Text.StringBuilder";

        $newString.AppendLine("127.0.0.1   web-platform.test")
        $newString.AppendLine("127.0.0.1   www1.web-platform.test")
        $newString.AppendLine("127.0.0.1   www2.web-platform.test")
        $newString.AppendLine("127.0.0.1   xn--n8j6ds53lwwkrqhv28a.web-platform.test")
        $newString.AppendLine("127.0.0.1   xn--lve-6lad.web-platform.test")
        $newString.AppendLine("0.0.0.0   nonexistent-origin.web-platform.test")

    Add-Content $hostsLocation $newString
    Write-Host "HOSTS file modified"
    }
}
else {
    Write-Host "Not setting the HOSTS file"
}
Write-Host

#########################################################################
# Install Ahem Font
#########################################################################
if ($InstallAhem) {
    Write-Host "Installing Ahem"
    $FONTS = 0x14
    $objShell = New-Object -ComObject Shell.Application
    $objFolder = $objShell.Namespace($FONTS)
    (new-object net.webclient).DownloadFile('https://github.com/w3c/web-platform-tests/raw/master/fonts/Ahem.ttf','c:\tools\ahem.ttf')

    if (!(Test-Path "$systemDrive\windows\fonts\ahem_0.ttf")) {
        $objFolder.CopyHere("$toolsTarget\ahem.ttf", 0x10)
    }
    Write-Host "Ahem Installed"
}
else {
    Write-Host "Not installing Ahem"
}

#########################################################################
# Kick off a run of the tests so that the manifest is created
#########################################################################
if ($RunTests) {
    Write-Host "Running a simple test to make sure it worked."
    "$repoTarget\python wpt run edge dom/events/CustomEvent.html"
}
else {
    Write-Host "Not Running any tests. To run tests nav to the WPT repo"
    Write-Host "python wpt run edge "
}
Write-Host
Write-Host "Done."