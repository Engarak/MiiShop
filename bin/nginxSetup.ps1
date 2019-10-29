[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")  

$Form = New-Object System.Windows.Forms.Form    
$Form.Size = New-Object System.Drawing.Size(600,400)  
$Form.Text='Setup Webserver'
$Form.FormBorderStyle = 'Fixed3D'
$Form.MaximizeBox = $false
$miiShopRoot=(get-item $PSScriptRoot).Parent.FullName
$icoPath=(Resolve-Path ('{0}\images\favicon.ico' -f $miiShopRoot)).Path
$Form.Icon = $icoPath
$dateFormat = 'M-d-y-hh_mm_ss'
$date=(get-date).ToString($dateFormat)
$outputLog = "..\logs\miiShop_$date.log"

############################################## Start functions

function Write-OutLog
{
    param($message)
    if($outputBox.text -eq '')
    {
        #output to text box (empty)
        $outputMessage = ('{0} - {1}' -f $(get-date -Format 'yyyy-MM-dd HH:mm:ss') ,$message)    
        $outputBox.text=$outputMessage 

        #output to log file
        $outputMessage | out-file -FilePath $outputLog -Append

        #refresh form
        $Form.Refresh()
    }
    else
    {
        #output to text box (1 row or more already in box)
        $priorText=$outputBox.text+"`r`n"
        $outputMessage = ('{0}{1} - {2}' -f $priorText,$(get-date -Format 'yyyy-MM-dd HH:mm:ss'),$message)
        $outputBox.Text=$outputMessage

        #output to log file
        $outputMessage | out-file -FilePath $outputLog -Append

        #refresh form
        $Form.Refresh()
    }
    
}

function setup-webserver
{
if([System.Environment]::OSVersion.Platform.ToString() -eq 'Win32NT')
{
    #Ta-da a more robust webserver
    Write-OutLog -message 'Starting Windows webserver config'
    Write-OutLog -message 'Downloading Webserver (NGINX)...'
    if(Test-Path '.\nginx-1.16.1.zip')
    {
        Write-OutLog -message 'Removing prior downloads'
        remove-item '.\nginx-1.16.1.zip'
    }
    #download nginx version that is supported (1.16.1) - I'll try to keep up on versions for security sake
    Invoke-WebRequest -Uri "http://nginx.org/download/nginx-1.16.1.zip" -OutFile '.\nginx-1.16.1.zip'
    if(test-path '.\nginx')
    {
        #Backup old nginx install in case need of roll back
        $newFolderName = ('.\nginx_{0}' -f $(get-date -f 'yyyy-MM-dd_HHmmss'))
        Write-OutLog -message 'Backing up old webserver install'
        rename-item '.\nginx' $newFolderName
        #copy over games for re-scan as they should be properly formatted
        Move-Item "$newFolderName\html\cia" '.\nginx\html\'
    }
    Write-OutLog -message 'Unzipping...'
    Expand-Archive '.\nginx-1.16.1.zip' -DestinationPath ".\" 
    Rename-Item  -path '.\nginx-1.16.1' -NewName '.\nginx' -Force


    Remove-Item '.\nginx-1.16.1.zip' -Force
    Write-OutLog -message 'Obtaining default configuation'
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Engarak/MiiShop/master/web/nginx.conf" -OutFile '.\nginx\conf\nginx.conf' 
    Write-OutLog -message 'Setting firewall rules if needed'
    #New firewall check/create - Inbound
    $in = Get-NetFirewallRule -DisplayName 'MiiShop Web port - In' 2> $null; if ($in) { write-output ('{0} Inbound rule already exists, skipping' -f $(Get-Date -Format s)); } else { write-output ('{0} Inbound rule does not exists, creating it' -f $(Get-Date -Format s));netsh advfirewall firewall add rule name="MiiShop Web port - In" dir=in action=allow protocol=TCP localport=80 | Out-Null; }
    #New firewall check/create - Inbound
    $out = Get-NetFirewallRule -DisplayName 'MiiShop Web port - Out' 2> $null; if ($out) { write-output ('{0} Outbound rule already exists, skipping' -f $(Get-Date -Format s)); } else { write-output ('{0} Outbound rule does not exists, creating it' -f $(Get-Date -Format s));netsh advfirewall firewall add rule name="MiiShop Web port - Out" dir=out action=allow protocol=TCP localport=80 | Out-Null; }
    Write-OutLog -message 'Completed setup of web server.  If this is your first run, make sure to create your main page before starting the webserver.'
}

<#if Linux or macOS...TBD
else if([System.Environment]::OSVersion.Platform -eq 'Unix')
{

    Write-OutLog -message 'Starting Linux/macOS webserver config'
    
}


#>
}

############################################## end functions

############################################## Start text fields

$outputBox = New-Object System.Windows.Forms.TextBox 
$outputBox.Location = New-Object System.Drawing.Size(10,10) 
$outputBox.Size = New-Object System.Drawing.Size(565,300) 
$outputBox.ReadOnly = $True
$outputBox.MultiLine = $True 
#$outputBox.ScrollBars = "Vertical" 
$Form.Controls.Add($outputBox) 

############################################## end text fields

############################################## Start buttons

$btnStart = New-Object System.Windows.Forms.Button 
$btnStart.Location = New-Object System.Drawing.Size(175,325) 
$btnStart.Size = New-Object System.Drawing.Size(110,30) 
$btnStart.Text = "&Start Setup" 
$btnStart.Add_Click({setup-webserver}) 

$btnClose = New-Object System.Windows.Forms.Button 
$btnClose.Location = New-Object System.Drawing.Size(300,325) 
$btnClose.Size = New-Object System.Drawing.Size(110,30) 
$btnClose.Text = "&Close" 
$btnClose.Add_Click({$Form.Close()}) 
$Form.Controls.AddRange(@($btnClose,$btnStart)) 

############################################## end buttons

$Form.Add_Shown({$Form.Activate()})
[void] $Form.ShowDialog()