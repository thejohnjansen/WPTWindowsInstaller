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
$repoTarget = "$documentsFolder\github\wpt"

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
Write-Host

#########################################################################
# These tests use a popup, so disable edge popup blocker
#########################################################################
Write-Host "Setting regkey to disable popup blocker for web-platform.test"
$registryPath = "HKCU:Software\Classes\Local Settings\Software\Microsoft" +
"\Windows\CurrentVersion\AppContainer\Storage\" +
"microsoft.microsoftedge_8wekyb3d8bbwe\MicrosoftEdge\New Windows\Allow"

$Name = "*.web-platform.test"

if (!(Test-Path $registryPath)) {
    New-Item -Path $registryPath -Force | Out-Null
}

New-ItemProperty -Path $registryPath -Name $Name -PropertyType Binary -Value ([byte[]](0x00, 0x00)) -Force | Out-Null

$Name = "*.w3c-test.org"

if (!(Test-Path $registryPath)) {
    New-Item -Path $registryPath -Force | Out-Null
}

New-ItemProperty -Path $registryPath -Name $Name -PropertyType Binary -Value ([byte[]](0x00, 0x00)) -Force | Out-Null

Write-Host "Registry set"
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
# if you do not have chocolatey installed, this will fail;
# that just means you have to exit and relaunch the PS session manually
RefreshEnv
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
    # refresh here will fail if chocolately is not install
    # that just means you have to exit and 
    # relaunch the PS session manually
    RefreshEnv
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

    (new-object net.webclient).DownloadFile('https://bootstrap.pypa.io/get-pip.py', $pipDest)
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
    git clone "https://github.com/web-platform-tests/wpt.git" $repoTarget
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
    $destinationFolder.CopyHere($zipPackage.Items(), 0x14)
    Write-Host "ChromeDriver Installed"

    # MicrosoftWebDriver

    # make sure webdriver is not already in the drivers folder
    $dest = "$driverTarget\MicrosoftWebDriver.exe"
    $alreadyInstalled = (Test-Path $dest)

    if ($alreadyInstalled) {
        Write-Host "WebDriver is already in the $driverTarget directory. Not installing."
    }
    else {
        $regKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
        $buildType = (Get-ItemProperty $regKey).ProductName
        $buildNumber = (Get-ItemProperty $regKey).CurrentBuildNumber
        
        if ($buildNumber -gt 17134) {
            # use a fod
            DISM.exe /Online /Add-Capability /CapabilityName:Microsoft.WebDriver~~~~0.0.1.0
        }
        else {
            # Set the version to be Current RTM version
            $mwdVersion = "F/8/A/F8AF50AB-3C3A-4BC4-8773-DC27B32988DD"

            switch ($buildNumber) {
                17134 { $wmdVersion = "F/8/A/F8AF50AB-3C3A-4BC4-8773-DC27B32988DD" }
                16299 { $wmdVersion = "D/4/1/D417998A-58EE-4EFE-A7CC-39EF9E020768" }
                15063 { $wmdVersion = "3/4/2/342316D7-EBE0-4F10-ABA2-AE8E0CDF36DD" }
                14393 { $wmdVersion = "3/2/D/32D3E464-F2EF-490F-841B-05D53C848D15" }
                10586 { $wmdVersion = "C/0/7/C07EBF21-5305-4EC8-83B1-A6FCC8F93F45" }
                10240 { $wmdVersion = "8/D/0/8D0D08CF-790D-4586-B726-C6469A9ED49C" }
                default {}
            }

            $url = "https://download.microsoft.com/download/$mwdVersion/MicrosoftWebDriver.exe"

            (new-object net.webclient).DownloadFile($url, $dest)
        }
    }
    
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
    $wordToFind = "web-platform.test"
    $hostsLocation = "$env:SystemRoot\System32\drivers\etc\hosts"

    $file = Get-Content $hostsLocation
    $containsWord = $file | % {$_ -match $wordToFind}

    # if the file already contains web-platform.test, don't do anything
    If (!($containsWord -contains $true)) {
        Push-Location -Path $repoTarget
        python wpt make-hosts-file | Out-File $hostsLocation -Encoding ascii -Append
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
    $alreadyInstalled = (Test-Path "$systemDrive\windows\fonts\ahem.ttf") -or 
    (Test-Path "$systemDrive\windows\fonts\ahem_0.ttf")

    if (!($alreadyInstalled)) {
        $FONTS = 0x14
        $objShell = New-Object -ComObject Shell.Application
        $objFolder = $objShell.Namespace($FONTS)
        (new-object net.webclient).DownloadFile(
            "https://github.com/w3c/web-platform-tests/raw/master/fonts/Ahem.ttf", 
            "$toolsTarget\ahem.ttf")
        $objFolder.CopyHere("$toolsTarget\ahem.ttf", 0x10)
    }
    Write-Host "Ahem Installed"
}
else {
    Write-Host "Not installing Ahem"
}
Write-Host

#########################################################################
# Kick off a run of the tests so that the manifest is created
#########################################################################
if ($RunTests) {
    Write-Host "Running a simple test to make sure it worked."
    Write-Host "Doing so will take a long time, go get some coffee."
    Set-Location -Path $repoTarget
    python wpt run edge dom/events/CustomEvent.html
}
else {
    Write-Host "Not Running any tests. To run tests nav to the WPT repo"
    Write-Host "python wpt run edge"
}
Write-Host
Write-Host "Done."
