# WPTWindowsInstaller #

A powershell script for getting a machine ready to run Web Platform Tests from the W3C.

## Instructions ##

This script assumes you do not have any tooling installed. It will install everything
for you. Simply download the repo as a zip, extract it to some directory
then:
Copy the .ps1 to your desktop
Launch a PowerShell window as an Admin
Set the exection policy so you can run the script:
``` powershell
 Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Unrestricted
```
Run the WindowsInstallScript

## Test Repo and Test Harness information ##

Since this is just about getting the machine setup, it
would do you good to check out the instructions for
after you are successful.

In the [WPT Test Suite] (https://github.com/w3c/web-platform-tests) readme.md
you can see how to run via 
"python wpt run"