<# This form was created using POSHGUI.com  a free online gui designer for PowerShell
.NAME
    Untitled
#>

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()
$miiShopRoot=(get-item $PSScriptRoot).Parent.FullName
$icoPath=(Resolve-Path ('{0}\images\favicon.ico' -f $miiShopRoot)).Path
############################################# Start Form
$frmSettings                     = New-Object system.Windows.Forms.Form
$frmSettings.ClientSize          = '442,450'
$frmSettings.text                = "Settings"
$frmSettings.TopMost             = $false
$frmSettings.AutoScroll          = $True
$frmSettings.icon                = $icoPath
############################################## End Form 
############################################## Start Group
$grpSettings                     = New-Object system.Windows.Forms.Groupbox
$grpSettings.height              = 409
$grpSettings.width               = 406
$grpSettings.text                = "Settings"
$grpSettings.location            = New-Object System.Drawing.Point(20,21)
############################################## End Group
############################################## Start Labels
$Label1                          = New-Object system.Windows.Forms.Label
$Label1.text                     = "Port"
$Label1.AutoSize                 = $true
$Label1.width                    = 25
$Label1.height                   = 10
$Label1.location                 = New-Object System.Drawing.Point(104,20)
$Label1.Font                     = 'Microsoft Sans Serif,10'

$Label2                          = New-Object system.Windows.Forms.Label
$Label2.text                     = "Debug"
$Label2.AutoSize                 = $true
$Label2.width                    = 25
$Label2.height                   = 10
$Label2.location                 = New-Object System.Drawing.Point(89,47)
$Label2.Font                     = 'Microsoft Sans Serif,10'

$Label3                          = New-Object system.Windows.Forms.Label
$Label3.text                     = "Background Path"
$Label3.AutoSize                 = $true
$Label3.width                    = 25
$Label3.height                   = 10
$Label3.location                 = New-Object System.Drawing.Point(30,74)
$Label3.Font                     = 'Microsoft Sans Serif,10'

$Label4                          = New-Object system.Windows.Forms.Label
$Label4.text                     = "Game Database"
$Label4.AutoSize                 = $true
$Label4.width                    = 25
$Label4.height                   = 10
$Label4.location                 = New-Object System.Drawing.Point(30,102)
$Label4.Font                     = 'Microsoft Sans Serif,10'

############################################## End Labels
############################################## Start text fields
$txtPort                         = New-Object system.Windows.Forms.TextBox
$txtPort.multiline               = $false
$txtPort.width                   = 100
$txtPort.height                  = 20
$txtPort.location                = New-Object System.Drawing.Point(150,17)
$txtPort.Font                    = 'Microsoft Sans Serif,10'

$txtDebug                        = New-Object system.Windows.Forms.TextBox
$txtDebug.multiline              = $false
$txtDebug.width                  = 100
$txtDebug.height                 = 20
$txtDebug.location               = New-Object System.Drawing.Point(150,47)
$txtDebug.Font                   = 'Microsoft Sans Serif,10'

$txtBGPath                       = New-Object system.Windows.Forms.TextBox
$txtBGPath.multiline             = $false
$txtBGPath.width                 = 236
$txtBGPath.height                = 20
$txtBGPath.location              = New-Object System.Drawing.Point(150,74)
$txtBGPath.Font                  = 'Microsoft Sans Serif,10'

$outputBox                       = New-Object system.Windows.Forms.TextBox
$outputBox.multiline             = $true
$outputBox.width                 = 353
$outputBox.height                = 218
$outputBox.location              = New-Object System.Drawing.Point(24,136)
$outputBox.Font                  = 'Microsoft Sans Serif,10'
$outputBox.ReadOnly              = $True

############################################## end text fields
$cboDatabase                     = New-Object system.Windows.Forms.ComboBox
$cboDatabase.width               = 150
$cboDatabase.height              = 20
$cboDatabase.location            = New-Object System.Drawing.Point(150,102)
$cboDatabase.Font                = 'Microsoft Sans Serif,10'
############################################## Start buttons
$btnSave                         = New-Object system.Windows.Forms.Button
$btnSave.text                    = '&Save'
$btnSave.width                   = 60
$btnSave.height                  = 27
$btnSave.location                = New-Object System.Drawing.Point(73,371)
$btnSave.Font                    = 'Microsoft Sans Serif,10'
$btnSave.add_click({Save-Settings})

$btnClose                        = New-Object system.Windows.Forms.Button
$btnClose.text                   = '&Close'
$btnClose.width                  = 60
$btnClose.height                 = 28
$btnClose.location               = New-Object System.Drawing.Point(242,370)
$btnClose.Font                   = 'Microsoft Sans Serif,10'
$btnClose.Add_Click({$frmSettings.close()}) 

############################################## end buttons

$frmSettings.controls.AddRange(@($grpSettings))
$grpSettings.controls.AddRange(@($Label1,$Label2,$Label3,$Label4,$txtPort,$txtDebug,$txtBGPath,$cboDatabase,$btnSave,$btnClose,$outputBox))
###############################################Form End
###############################################Functions start

$dateFormat = 'M-d-y-hh_mm_ss'
$date=(get-date).ToString($dateFormat)
$outputLog = "..\logs\miiShop_$date.log"
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
        $frmSettings.Refresh()
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
        $frmSettings.Refresh()
    }
    
}

function Save-Settings
{
    #Check for config file
    Write-OutLog -message 'Checking for settings file'   
    $miiShopRoot=(get-item $PSScriptRoot).Parent.FullName
    $settingsPath=('{0}\database\settings.csv' -f $miiShopRoot)
    $dateFormat = 'M-d-y-hh_mm_ss'
    $date=(get-date).ToString($dateFormat)
    if(Test-Path $settingsPath)
    {
        #Backup config file if found
        Write-OutLog -message 'Backing up existing settings file' 
        Move-Item $settingsPath "..\backup\settings_$date.csv"
    }
    #Make new config file 
    Write-OutLog -message 'Saving Settings'  
    'Name,Value,Purpose'| out-file -FilePath $settingsPath -force
    ('port,{0},"webserver port"' -f $txtPort.Text)| out-file -FilePath $settingsPath -Append
    ('debug,{0},"a value with additional logging if needed in an error (0, no debugging, 1, with debugging).  Saved for future use(3-MAY-19)"' -f $txtDebug.Text)| out-file -FilePath $settingsPath -Append
    ('backgroundPath,{0},"Location of background image"' -f $txtBGPath.Text) | out-file -FilePath $settingsPath -Append
    ('gameDB,{2},""Location of database to match game library against (valid values: 3dsreleases.xml(default) or community.xml) (thanks to http://www.3dsdb.com/ and Madridi for access to the gbatemp community game database - https://gbatemp.net/members/madridi.124719/)" (valid values:{0}(default) or {1})"' -f "..\database\3dsreleases.xml","..\database\community.xml",$cboDatabase.Text) | out-file -FilePath $settingsPath -Append
    
    #Remake nginx.conf
    Write-OutLog -message 'Updating Webserver Configuration'
    'worker_processes  1;'| out-file -FilePath '.\nginx\conf\nginx.conf' -force  -Encoding utf8
    'events {'| out-file -FilePath '.\nginx\conf\nginx.conf' -force -Append -Encoding utf8
    '    worker_connections  1024;'| out-file -FilePath '.\nginx\conf\nginx.conf' -force -Append -Encoding utf8
    '}'| out-file -FilePath '.\nginx\conf\nginx.conf' -force -Append -Encoding utf8
    'http {'| out-file -FilePath '.\nginx\conf\nginx.conf' -force -Append -Encoding utf8
    '    include       mime.types;'| out-file -FilePath '.\nginx\conf\nginx.conf' -force -Append -Encoding utf8
    '    default_type  application/octet-stream;'| out-file -FilePath '.\nginx\conf\nginx.conf' -force -Append -Encoding utf8
    '    sendfile        on;'| out-file -FilePath '.\nginx\conf\nginx.conf' -force -Append -Encoding utf8
    '    keepalive_timeout  65;'| out-file -FilePath '.\nginx\conf\nginx.conf' -force -Append -Encoding utf8
    '    server {'| out-file -FilePath '.\nginx\conf\nginx.conf' -force -Append -Encoding utf8
    '        listen       {0};' -f $txtPort.Text| out-file -FilePath '.\nginx\conf\nginx.conf' -force -Append -Encoding utf8
    '        server_name  localhost;'| out-file -FilePath '.\nginx\conf\nginx.conf' -force -Append -Encoding utf8
    '        location / {'| out-file -FilePath '.\nginx\conf\nginx.conf' -force -Append -Encoding utf8
    '            root   html;'| out-file -FilePath '.\nginx\conf\nginx.conf' -force -Append -Encoding utf8
    '            index  main.html index.html index.htm;'| out-file -FilePath '.\nginx\conf\nginx.conf' -force -Append -Encoding utf8
    '                    }'| out-file -FilePath '.\nginx\conf\nginx.conf' -force -Append -Encoding utf8		
    '        error_page   500 502 503 504  /50x.html;'| out-file -FilePath '.\nginx\conf\nginx.conf' -force -Append -Encoding utf8
    '        location = /50x.html {'| out-file -FilePath '.\nginx\conf\nginx.conf' -force -Append -Encoding utf8
    '            root   html;'| out-file -FilePath '.\nginx\conf\nginx.conf' -force -Append -Encoding utf8
    '        }'| out-file -FilePath '.\nginx\conf\nginx.conf' -force -Append -Encoding utf8       
    '    }'| out-file -FilePath '.\nginx\conf\nginx.conf' -force -Append -Encoding utf8
    '}'| out-file -FilePath '.\nginx\conf\nginx.conf' -force -Append -Encoding utf8
    #Done - Reload config
    Write-OutLog -message 'All Settings Saved. If miiShop is running please stop and re-start it to reflect the configuration changes'
    Start-Config    
}

function get-settings 
{
    #load settings, make if they don't exist
    Write-OutLog -message 'Checking for settings file'   
    $miiShopRoot=(get-item $PSScriptRoot).Parent.FullName
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
function Start-Config
{
    #load function to get the settings and put them in the form elements
    $settings = get-settings
    $port=$settings.Where({$PSItem.Name -eq 'port'}).Value
    $debug=$settings.Where({$PSItem.Name -eq 'debug'}).Value
    $backgroundPath =$settings.Where({$PSItem.Name -eq 'backgroundPath'}).Value
    $gameDB = $settings.Where({$PSItem.Name -eq 'gameDB'}).Value
    $txtPort.Text=$port
    $txtDebug.Text=$debug
    $txtBGPath.Text=$backgroundPath
    $cboDatabase.Items.Add('3dsreleases.xml')
    $cboDatabase.Items.Add('community.xml')
    $cboDatabase.Text=$gameDB

}

#############################################End functions
$frmSettings.Add_load({start-config})
$frmSettings.Add_Shown({$frmSettings.Activate()})
[void] $frmSettings.ShowDialog()