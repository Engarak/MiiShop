[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")  

$Form = New-Object System.Windows.Forms.Form    
$Form.Size = New-Object System.Drawing.Size(600,400)  
$Form.Text='Update miiShop'
$Form.FormBorderStyle = 'Fixed3D'
$Form.MaximizeBox = $false
$miiShopRoot=(get-item $PSScriptRoot).Parent.FullName
$icoPath=(Resolve-Path ('{0}\images\favicon.ico' -f $miiShopRoot)).Path
$Form.Icon = $icoPath
$dateFormat = 'M-d-y-hh_mm_ss'
$date=(get-date).ToString($dateFormat)
$outputLog = "$miiShopRoot\logs\update_$date.log"
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
        $message | out-file -FilePath $outputLog -Append

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
        $message | out-file -FilePath $outputLog -Append

        #refresh form
        $Form.Refresh()
    }
    
}



function Start-Update
{
    Set-Location $PSScriptRoot
    Write-OutLog -message 'Downloading the most current miiShop core files'
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Engarak/MiiShop/master/bin/makeMain.ps1" -OutFile '.\makeMain.ps1'
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Engarak/MiiShop/master/bin/nginxSetup.ps1" -OutFile '.\nginxSetup.ps1'
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Engarak/MiiShop/master/bin/settings.ps1" -OutFile '.\settings.ps1'
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Engarak/MiiShop/master/bin/startmiiShop.ps1" -OutFile '.\startmiiShop.ps1'
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Engarak/MiiShop/master/miiShop.ps1" -OutFile '..\miiShop.ps1'
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Engarak/MiiShop/master/start.bat" -OutFile '..\start.bat'
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Engarak/MiiShop/master/main.mnu" -OutFile '..\main.mnu'
    Write-OutLog -message 'Downloading completed.  Please close out all miiShop windows and re-launch it.'
    
}


############################################## end functions

############################################## Start text fields

$outputBox = New-Object System.Windows.Forms.TextBox 
$outputBox.Location = New-Object System.Drawing.Size(10,10) 
$outputBox.Size = New-Object System.Drawing.Size(565,300) 
$outputBox.MultiLine = $True 
$outputBox.ScrollBars = "Vertical" 
$outputBox.ReadOnly = $True
$Form.Controls.Add($outputBox) 

############################################## end text fields

############################################## Start buttons


$btnClose = New-Object System.Windows.Forms.Button 
$btnClose.Location = New-Object System.Drawing.Size(230,320) 
$btnClose.Size = New-Object System.Drawing.Size(110,30) 
$btnClose.Text = "&Close" 
$btnClose.Add_Click({$Form.close()}) 
$Form.Controls.AddRange(@($btnClose)) 

############################################## end buttons

$Form.Add_load({Start-Update})
$Form.Add_Shown({$Form.Activate()})
[void] $Form.ShowDialog()