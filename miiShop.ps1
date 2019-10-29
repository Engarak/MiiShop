if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }
#Requires -version 5.1
function check-InstallModule
{
    #install modules if not installed.  This way I can help setup the client with dependant modules, finally!
    param($moduleName)
    if([string]::IsNullOrEmpty($moduleName))
    {
        Write-Output 'Error: No module specified, this is an issue in the code most likely'
        break;
    }
    if (Get-Module -ListAvailable -Name $moduleName) 
    {
        Write-Output 'Menu Module exists, skipping install.'
    } 
    else 
    {
        if(-not(Install-Module -Name $moduleName -Confirm:$false -Force -ErrorAction Stop))
        {
            Write-Output ('Module {0} installed successfully' -f $moduleName)
        }
        else
        {
            #try to catch our errors installing
            $ErrorMessage = $_.Exception.Message
            $FailedItem = $_.Exception.ItemName
            Write-Output 'Error Encountered'
            Write-Output $ErrorMessage
            Write-Output 'Failed Item'
            Write-Output $FailedItem
            break;
        }
    }
}

#Make sure we're in the right operating directory
Set-Location -path $PSScriptRoot

#the start of a launcher for miiSHop, Thanks so much 
check-InstallModule PSScriptMenuGui
#check-InstallModule PoSHServer - Bye bye, PoSH server, thanks for the help...hello NGINX

Show-ScriptMenuGui -csvPath '.\main.mnu' -windowTitle 'miiShop' -iconPath '.\images\favicon.png' -buttonForegroundColor GhostWhite -buttonBackgroundColor DarkOrange -hideConsole
