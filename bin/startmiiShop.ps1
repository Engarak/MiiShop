[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")  

$Form = New-Object System.Windows.Forms.Form    
$Form.Size = New-Object System.Drawing.Size(600,400)  
$Form.Text='Start/Stop miiShop'
$Form.FormBorderStyle = 'Fixed3D'
$Form.MaximizeBox = $false
$miiShopRoot=(get-item $PSScriptRoot).Parent.FullName
$icoPath=(Resolve-Path ('{0}\images\favicon.ico' -f $miiShopRoot)).Path
$Form.Icon = $icoPath
$Form.add_FormClosing({stop-miiShop})
$dateFormat = 'M-d-y-hh_mm_ss'
$date=(get-date).ToString($dateFormat)
$outputLog = "$miiShopRoot\logs\miiShop_$date.log"
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

function get-settings 
{
    #Get settings, load data or create settings file if not found
    Write-OutLog -message 'Checking for settings file'
    $settingsPath=('{0}\database\settings.csv' -f $miiShopRoot)
    if(Test-Path $settingsPath)
    {
        Write-OutLog -message 'settings file found, loading data'
        $settings = Import-Csv $settingsPath      
    }
    else
    {
        Write-OutLog -message 'Settings file not found, creating file'
        'Name,Value,Purpose'| out-file -FilePath $settingsPath -force
        'port,80,"webserver port"'| out-file -FilePath $settingsPath -Append
        'debug,0,"a value with additional logging if needed in an error (0, no debugging, 1, with debugging).  Saved for future use(3-MAY-19)"'| out-file -FilePath $settingsPath -Append
        ('backgroundPath,{0},"Location of background image"' -f ".\nginx\html\images\background.png") | out-file -FilePath $settingsPath -Append
        ('gameDB,{0},""Location of database to match game library against (valid values: 3dsreleases.xml(default) or community.xml) (thanks to http://www.3dsdb.com/ and Madridi for access to the gbatemp community game database - https://gbatemp.net/members/madridi.124719/)" (valid values:{0}(default) or {1})"' -f "..\database\3dsreleases.xml","..\database\community.xml") | out-file -FilePath $settingsPath -Append
        $settings = Import-Csv $settingsPath
    }
    return $settings

}

function start-miiShop
{    
    Set-Location $PSScriptRoot
    #Get settings
    $settings = get-settings 
    $port=$settings.Where({$PSItem.Name -eq 'port'}).Value
    $debug=$settings.Where({$PSItem.Name -eq 'debug'}).Value
    # Saved for future use
    <#
    $gamePath=$settings.Where({$PSItem.Name -eq 'gamePath'}).Value
    $backgroundPath =$settings.Where({$PSItem.Name -eq 'backgroundPath'}).Value
    $gameDB = $settings.Where({$PSItem.Name -eq 'gameDB'}).Value
    $rebuild = 1
    #>

    #Get IP
    Write-OutLog -message 'Obtaining Local IP'
    $myIPaddy='127.0.0.1'
    $myIPaddy = @(@(Get-WmiObject Win32_NetworkAdapterConfiguration | Select-Object -ExpandProperty IPAddress) -like "*.*")[0].ToString().Trim()
    Write-OutLog -message ('Found IP Address {0}, Opening miiShop in your default browser' -f $myIPaddy)
    #Build server link and launch browser
    $localURL = ('http://{0}:{1}' -f $myIPaddy,$port)
    (New-Object -Com Shell.Application).Open($localURL)
    Write-OutLog -message 'Starting miiShop, to close use the Close button, not the X in the corner.'
    #Launch nginx
    $svrPath =(resolve-path ('{0}\bin\nginx\nginx.exe' -f $miiShopRoot)).Path   
    $changePath = ('{0}\bin\nginx' -f $miiShopRoot)
    if($debug -eq 1)
    {
        Write-OutLog -message "miiShopRoot $miiShopRoot"
        Write-OutLog -message "Server Path $svrPath"
        Write-OutLog -message "dir to change to $changePath"
        #pause
    }
    Set-Location $changePath
    Start-Process $svrPath -PassThru

}

function stop-miiShop
{
    #Stop if running, and if not just say goodbye and change directory back to bin folder
    #add closing action tied to this process, so if someone uses the X it will close the webserver out
    if(Get-Process -Name nginx -ErrorAction SilentlyContinue)
    {
        Write-OutLog -message 'Stopping miiShop server'
        Stop-Process -Name nginx -Force -Confirm:$false -ErrorAction SilentlyContinue
        Write-OutLog -message 'miiShop is not running, goodbye!'
        Set-Location "$miiShopRoot\bin"
    }
    else
    {
        Write-OutLog -message 'miiShop is not running, goodbye!'
        Set-Location "$miiShopRoot\bin"
    }


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

$btnStart = New-Object System.Windows.Forms.Button 
$btnStart.Location = New-Object System.Drawing.Size(175,325) 
$btnStart.Size = New-Object System.Drawing.Size(110,30) 
$btnStart.Text = "&Start miiShop" 
$btnStart.Add_Click({start-miiShop}) 

$btnClose = New-Object System.Windows.Forms.Button 
$btnClose.Location = New-Object System.Drawing.Size(300,325) 
$btnClose.Size = New-Object System.Drawing.Size(110,30) 
$btnClose.Text = "&Stop miiShop" 
$btnClose.Add_Click({stop-miiShop}) 
$Form.Controls.AddRange(@($btnClose,$btnStart)) 

############################################## end buttons

$Form.Add_Shown({$Form.Activate()})
[void] $Form.ShowDialog()