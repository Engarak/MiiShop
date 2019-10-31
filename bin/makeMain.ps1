[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")  

$Form = New-Object System.Windows.Forms.Form    
$Form.Size = New-Object System.Drawing.Size(600,400)  
$Form.Text='Make Main Page'
$Form.FormBorderStyle = 'Fixed3D'
$Form.MaximizeBox = $false
$miiShopRoot=(get-item $PSScriptRoot).Parent.FullName
$icoPath=(Resolve-Path ('{0}\images\favicon.ico' -f $miiShopRoot)).Path
$Form.Icon = $icoPath
$Form.AutoScroll=$True
$dateFormat = 'M-d-y-hh_mm_ss'
$date=(get-date).ToString($dateFormat)
$outputLog = "..\logs\makemain_$date.log"
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
$btnStart.Text = "&Create page" 
$btnStart.Add_Click({start-makingpage}) 

$btnClose = New-Object System.Windows.Forms.Button 
$btnClose.Location = New-Object System.Drawing.Size(300,325) 
$btnClose.Size = New-Object System.Drawing.Size(110,30) 
$btnClose.Text = "&Close" 
$btnClose.Add_Click({$Form.Close()}) 
$Form.Controls.AddRange(@($btnClose,$btnStart)) 


############################################## end buttons
############################################## Start functions

function Write-OutLog
{
    param($message)
    #if($outputBox.text -eq '')
    #{
        #output to text box (empty)
        $outputMessage = ('{0} - {1} {2}' -f $(get-date -Format 'yyyy-MM-dd HH:mm:ss') ,$message,"`r`n")   
        $outputBox.AppendText($outputMessage) 

        #output to log file
        $message | out-file -FilePath $outputLog -Append

        #refresh form
        $Form.Refresh()
    <#}
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
    }#>
    
}

function checkmake-folder ([string] $folderName)
{
    #Just had to create some folders, and wanted to test if they existed first, this was to save 10 lines of code...worth it?
    if(!(test-path $folderName))
    {
        New-Item -ItemType Directory -Force -Path $folderName
    }

}

# thanks to https://techibee.com/powershell/convert-from-any-to-any-bytes-kb-mb-gb-tb-using-powershell/2376 for simple file size convertion
function Convert-Size {            
[cmdletbinding()]            
param(            
    [validateset("Bytes","KB","MB","GB","TB")]            
    [string]$From,            
    [validateset("Bytes","KB","MB","GB","TB")]            
    [string]$To,            
    [Parameter(Mandatory=$true)]            
    [double]$Value,            
    [int]$Precision = 4            
)            
switch($From) {            
    "Bytes" {$value = $Value }            
    "KB" {$value = $Value * 1024 }            
    "MB" {$value = $Value * 1024 * 1024}            
    "GB" {$value = $Value * 1024 * 1024 * 1024}            
    "TB" {$value = $Value * 1024 * 1024 * 1024 * 1024}            
}            
            
switch ($To) {            
    "Bytes" {return $value}            
    "KB" {$Value = $Value/1KB}            
    "MB" {$Value = $Value/1MB}            
    "GB" {$Value = $Value/1GB}            
    "TB" {$Value = $Value/1TB}            
            
}            
            
return [Math]::Round($value,$Precision,[MidPointRounding]::AwayFromZero)            
            
}            

function get-settings 
{
    Write-OutLog -message 'Checking for settings file'
    $settingsPath=('{0}\database\settings.csv' -f $miiShopRoot)
    if(Test-Path $settingsPath)
    {
        Write-OutLog -message 'Settings file found, importing settings'
        $settings = import-csv $settingsPath
    }
        Write-OutLog -message 'Settings file not found, creating file'
        'Name,Value,Purpose'| out-file -FilePath $settingsPath -force
        'port,80,"webserver port"'| out-file -FilePath $settingsPath -Append
        'debug,0,"a value with additional logging if needed in an error (0, no debugging, 1, with debugging).  Saved for future use(3-MAY-19)"'| out-file -FilePath $settingsPath -Append
        ('backgroundPath,{0},"Location of background image"' -f "background.jpg") | out-file -FilePath $settingsPath -Append
        ('gameDB,{0},""Location of database to match game library against (valid values: 3dsreleases.xml(default) or community.xml) (thanks to http://www.3dsdb.com/ and Madridi for access to the gbatemp community game database - https://gbatemp.net/members/madridi.124719/)" (valid values:{0}(default) or {1})"' -f "..\database\3dsreleases.xml","..\database\community.xml") | out-file -FilePath $settingsPath -Append
        $settings = Import-Csv $settingsPath

    return $settings

}

# BIG thanks to Matt Painter for this code on Script Cener in Microsoft Tech Net - 'https://gallery.technet.microsoft.com/scriptcenter/f615d7e8-ed15-498d-b7cc-078377f523bf'
# Requires the internet because of this call, maybe see if I can find a way to build a QR code without.  But that's way off at this point.
function New-QR { 
<# 
    .Synopsis 
       Create New Quick Response Code 
     
    .Description 
       Create New Quick Response Code 
        
       Function uses Google API so script requires internet access. 
       Script will compose QR request and then download generated image.    
        
       New-QR returns the properties of the new QR code created.    
                                     
    .parameter fileName 
        file name of QR code to be created.  
        Can specify fullpath, please use .PNG file extension. 
        If specifying fullpath ensure directory structure exists.  
         
                          
    .parameter Message 
        Message to be encoded in QR code.  
        Script will check the message length to ensure it does not exceed the max allowed size 
        Purely numeric content allows for a larger storage capacity in code. 
         
        Message Examples 
        "TEL:0416123456" (Will call my cell phone) 
        "SMSTO:0416123456:Hi Matt,`nI am at your desk." (An SMS to me. Note the new line character) 
        "http://painterinfo.com" (Open this website) 
        "This is the Pishkin Building" (A plain text message encoded in the QR Code)  
         
    .parameter Enc 
        Allowed encoding types are: 
        UTF-8, Shift_JIS, ISO-8859-1 
        UTF-8 is default and recommended type 
         
    .parameter ECL 
        Error Correction Level 
         
        L - [Default] Allows recovery of up to 7% data loss 
        M - Allows recovery of up to 15% data loss 
        Q - Allows recovery of up to 25% data loss 
        H - Allows recovery of up to 30% data loss 
         
        Use L for maximum storage capacity in QR code 
        Use H if you think the QR code might get damaged or if you want to embed plain text or logo after. 
         
    .parameter Size 
        The QR code's physical size in pixels, not to be confused with the data storage size. 
        Function caters for several pre-set sizes and a custom size option 
        S - 75x75 
        M - 150x150 [default] 
        L - 300x300 
        X - 547x547 - This appears to be the maximum size that the API can produce. 
        C - Custom size to be used - Warning too small will result QR code generation failure. 
            If too large a value is specified then the 150x150 default will be generated instead. 
            Use -chs parameter in conjunction with -Size C or Custom size will default to 150x150 
                
    .parameter chs 
        This is the custom size of the image in pixels e.g. 150x150 
        This parameter is only read when -Size C parameter is specified. (Otherwise ignored) 
        Min = 50x50 [approximate] Large QR codes may need to be physically larger to fit the data. 
        Max = 547x547 
         
    .parameter margin 
        Defaults to 4 and it is recommended to leave it at that.  
        A white space margin of 4 is required for reliable QR code reading. 
        Valid Values are 1..4                       
       
   
   .Example 
       New-QR http://painterinfo.com 
        
    Description 
    ----------- 
       Creates a new QR code (URL)  
       Path to QR code image is returned by script 
        
    .Example 
       New-QR -Message "This is a test" -Size C -chs 200x200 
        
    Description 
    ----------- 
       Creates a new QR code (TEXT)  
       Custom image size 200x200 is created. 
       Path to QR code is returned by script 
        
    .Example 
       ii (New-QR -message TEL:0754419999 -Size L -ECL H).fullname  
        
    Description 
    ----------- 
       Creates a new QR code (Phone Number) and is opened with default image viewer. 
       -Size L (image size is 300x300 pixels) 
       -ECL H (30% of image is redundant)  
        
    .Example 
       Import-Csv "C:\QR\users.csv" | New-QR -S L 
        
    Description 
    -----------   
        Using the following CSV, multiple 300x300 QR Codes are generated.   
        
       "Message","Filename" 
        "TEL:0416123456","C:\QR\Matt.png" 
        "TEL:0417123456","C:\QR\John.png" 
        "TEL:0418123456","C:\QR\Ruth.png" 
        "TEL:0419123456","C:\QR\Fred.png"         
             
    .Inputs 
       psObject 
       (filename,Message) 
        
    .Outputs 
       psObject 
       (FullName,ErrorCorrrection,Margin,Dimensions,DataSize) 
            
    .Notes 
       NAME:      New-QR 
       PURPOSE:   Generate QR codes with PowerShell  
       VERSION:   1.0 
       AUTHOR:    Matthew Painter 
       LASTEDIT:  06/August/2011 
        
    .link 
        http://code.google.com/apis/chart/infographics/docs/qr_codes.html 
        
#> 
 
   
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "low")]  
     
    param( 
        [Parameter(  
        Mandatory=$false, 
        ValueFromPipeline=$false)] 
        $chs = "150x150", 
                                                     
        [Parameter(  
        Mandatory=$false, 
        ValueFromPipeline=$false)] 
        $ECL = "L", 
                                 
        [Parameter(  
        Mandatory=$false, 
        ValueFromPipeline=$false)] 
        $Enc = "UTF-8",         
                 
        [Parameter(  
        Mandatory=$false, 
        Position=1, 
        ValueFromPipelineByPropertyName = $true)] 
        [string]$fileName="$env:temp\QR.png", 
                                   
        [Parameter(  
        Mandatory=$false, 
        ValueFromPipeline=$false)] 
        $margin = 4,     
                                   
        [Parameter(  
        Mandatory=$true, 
        Position=0, 
        HelpMessage="Message to be encoded", 
        ValueFromPipelineByPropertyName = $true)] 
        [object]$Message,    
                                           
        [Parameter(  
        Mandatory=$false, 
        ValueFromPipeline=$false)] 
        $Size = "M"          
    ) 
     
    process 
    { 
        switch ($Size) # Pre-set Physical Size of QR Code image in pixels 
        { 
            "S" {$chs = "75x75"} 
            "M" {$chs = "150x150"} 
            "L" {$chs = "300x300"} 
            "X" {$chs = "547x547"} 
            "C" {If ($chs -imatch "[5-9][0-9][x][5-9][0-9]" -or  $chs -imatch "[1-5][0-4][0-9][x][1-5][0-4][0-9]") {write-verbose "Custom chs $chs"} else {Write-verbose "chs invalid, changing to default - 150x150"; $chs = "150x150"};  
                 $split = $chs.split("x");  
                 If ($split[0] -ne $split[1] ){$chs = "$($split[0])x$($split[0])"; Write-Verbose "Making chs symmetrical $chs"} 
                 If ($split[0] -gt 547){$chs = "547x547"} 
                 } 
            default {$chs = "150x150"} 
        }    
        
        switch ($ECL) # Error Correction Level 
        { 
            "L" {$chld = "L"} 
            "M" {$chld = "M"} 
            "Q" {$chld = "Q"} 
            "H" {$chld = "H"} 
            default {$chld = "L"} 
        } 
        
        switch ($Enc) # Encoding type 
        { 
            "UTF-8" {$choe = "UTF-8"} 
            "Shift_JIS" {$choe = "Shift_JIS"} 
            "ISO-8859-1" {$choe = "ISO-8859-1"} 
            default {$choe = "UTF-8"} 
        } 
         
        # Hash table of QR Code maximum data capacity. Limit is governed by Error Correction Level and data type   
        $Limit = @{  
            "LN"=7089;  
            "LA"=4296;  
            "MN"=5596;  
            "MA"=3391;  
            "QN"=3993;  
            "QA"=2420;  
            "HN"=3057;  
            "HA"=1852; 
        } 
    
         
        # Numeric or AlphaNumeric? 
        # Messages with purely numeric data type have a larger QR Code storage capacity.    
        $NorA="N" 
        for ($a = 1; $a -le $Message.length; $a++) {if (!($Message.substring($a-1,1) -match "[0-9]")){$NorA="A"; break}}     
         
         
        
        # Check Message length does not exceed the Code's specification limit.  
        if ($Message.length -gt $Limit."$chld$NorA")  
        { 
            Write-Verbose "Message Size Limit Exceeded"; Break 
        } 
        else 
        { 
            Write-Verbose "Message $(if ($NorA -eq "N"){"Purely Numeric"}else{"Not Purely Numeric"})" 
            Write-Verbose "Max Message Length $($Limit."$chld$NorA")" 
            Write-Verbose "Message Length $($Message.length) OK" 
        } 
         
         
        # Build URL and request QR Code from Google API 
        $chld = "$chld`|$margin" 
        $Message = $Message -replace(" ", "+")      
        $URL = "https://chart.googleapis.com/chart?chs=$chs&cht=qr&chld=$chld&choe=$choe&chl=$Message" 
        $req = [System.Net.HttpWebRequest]::Create($url) 
        $req.Proxy = [System.Net.WebRequest]::DefaultWebProxy 
        $req.Proxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials 
        try {$res = $req.GetResponse()} catch {Write-OutLog -message $URL; Write-error $error[0]; break} 
       
 
       
        # Save downloaded binary file    
        if($res.StatusCode -eq 200)  
        { 
            $reader = $res.GetResponseStream() 
            try {$writer = new-object System.IO.FileStream $fileName, "Create"}catch{Write-OutLog -message "Invalid File Path?"; break} 
            [byte[]]$buffer = new-object byte[] 4096 
 
            do 
            { 
                $count = $reader.Read($buffer, 0, $buffer.Length) 
                $writer.Write($buffer, 0, $count) 
            } while ($count -gt 0) 
           
            $reader.Close() 
            $writer.Flush() 
            $writer.Close() 
             
            # Output properties 
            $QRProperties = @{  
                FullName = (ls $filename).fullname 
                DataSize = $Message.length 
                Dimensions = $chs 
                ECLevel = $chld.split("|")[0]  
                Margin = $chld.split("|")[1]  
            } 
            New-Object PSObject -Property $QRProperties            
             
        }     
         
        Write-Verbose "FileName $fileName" 
        Write-Verbose "chs $chs" 
        Write-Verbose "chld $chld" 
        Write-Verbose "choe $choe"     
        Write-Verbose "URL $URL"  
        Write-Verbose "Http Status Code $($res.StatusCode)" 
        Write-Verbose "Message $Message"      
         
        $res.Close() 
    } 
} 

function get-CleanGamename ([String] $inputGame)
{
    $gameDisplayName = $inputGame
    $gameDisplayName = $gameDisplayName.replace('.cia','')
    $gameDisplayName = $gameDisplayName.replace('_',' ')  
    $gameDisplayName = $gameDisplayName.replace(' USA','')
    $gameDisplayName = $gameDisplayName.replace('(USA)','')
    $gameDisplayName = $gameDisplayName.replace('(EUR)','')          
    $gameDisplayName = $gameDisplayName.replace('EUR','')
    $gameDisplayName = $gameDisplayName.replace(' EU','')
    $gameDisplayName = $gameDisplayName.replace(' US','')
    $gameDisplayName = $gameDisplayName.replace('(US)','')
    $gameDisplayName = $gameDisplayName.replace('(RF)','')
    $gameDisplayName = $gameDisplayName.replace(' DEC','')
    $gameDisplayName = $gameDisplayName.replace('  ','')
    $gameDisplayName = $gameDisplayName.replace('  ','')
    $gameDisplayName = $gameDisplayName.replace('  ','')
    return $gameDisplayname 
}

function make-mainpage ([string] $myIP, [string]$backgroundPath)
{
    $settings = get-settings 
    $port=$settings.Where({$PSItem.Name -eq 'port'}).Value
    $debug=$settings.Where({$PSItem.Name -eq 'debug'}).Value
    $backgroundPath =$settings.Where({$PSItem.Name -eq 'backgroundPath'}).Value
    $gameDB = $settings.Where({$PSItem.Name -eq 'gameDB'}).Value   

    #move over legacy CIA's if they exist and backup old files we no longer need
    if(test-path '..\cias')
    {
        Write-OutLog 'Found legacy cias folder, migrating contents'
        Move-Item '..\cias\*.*' '.\nginx\html\cias'  -Force -Confirm:$false -ErrorAction SilentlyContinue
        Move-Item '..\cias' '..\backup' -Force -Confirm:$false -ErrorAction SilentlyContinue
        Move-Item '..\qr' '..\backup' -Force -Confirm:$false -ErrorAction SilentlyContinue
        Move-Item '..\PoSHServer-Standalone.ps1' '..\backup\PoSHServer-Standalone.ps1' -ErrorAction SilentlyContinue
        Move-Item '..\config.ps1' '..\backup\config.ps1' -ErrorAction SilentlyContinue
    }
    if(test-path '.\nginx\html\main.html')
    {
        Write-OutLog -message 'Backing up prior main.html'
        $dateFormat = 'M-d-y-hh_mm_ss'
        $date=(get-date).ToString($dateFormat)
        Move-Item '.\nginx\html\main.html' "..\backup\main.$date.html" -ErrorAction SilentlyContinue
        
        Write-OutLog -message 'Deleteing any backups found that are older than 7 days.'
        # Delete all files in back-up older than 7 days
        $Path = "..\backup\"
        $Daysback = "-7"
 
        $CurrentDate = Get-Date
        $DatetoDelete = $CurrentDate.AddDays($Daysback)
        Get-ChildItem $Path | Where-Object { $_.LastWriteTime -lt $DatetoDelete } | Remove-Item
    }
    else
    {        
        Write-OutLog -message 'No main.html exists, begin file creation'
    }
     
    #There probably is a better way, but html is forviging, so writing to a .html file as a text file, with correct tags but probably poor formatting

    
    #Rebuild page every time, so when I add custom background support it's easier to allow
    '<html>'|out-file -FilePath '.\nginx\html\main.html' -Force
    '<head>'|out-file -FilePath '.\nginx\html\main.html' -Append -Force
    '<title>3DS Game Directory</title>'|out-file -FilePath '.\nginx\html\main.html' -Append -Force

    #This is for changing the images for boxart and QR code without a page reload, just a reload of those images
    '<script src="https://code.jquery.com/jquery-1.12.4.min.js"></script>'|out-file -FilePath '.\nginx\html\main.html' -Append -Force

    '<script type="text/javascript">'|out-file -FilePath '.\nginx\html\main.html' -Append -Force
    '$(document).ready(function(){'|out-file -FilePath '.\nginx\html\main.html' -Append -Force
    '$("select.games").change(function(){'|out-file -FilePath '.\nginx\html\main.html' -Append -Force
    'var selectedGame = $(this).children("option:selected").val();'|out-file -FilePath '.\nginx\html\main.html' -Append -Force
    'var selectedGameInfo = selectedGame.split("|");'|out-file -FilePath '.\nginx\html\main.html' -Append -Force
    '    document.getElementById("qr").src=selectedGameInfo[0];'|out-file -FilePath '.\nginx\html\main.html' -Append -Force
    '    document.getElementById("name").innerHTML=selectedGameInfo[1];'|out-file -FilePath '.\nginx\html\main.html' -Append -Force
    '    document.getElementById("publisher").innerHTML=selectedGameInfo[2];'|out-file -FilePath '.\nginx\html\main.html' -Append -Force
    '    document.getElementById("serial").innerHTML=selectedGameInfo[3];'|out-file -FilePath '.\nginx\html\main.html' -Append -Force
    '    document.getElementById("imgBoxArt").style.backgroundImage = "url(" + selectedGameInfo[4] +")";'|out-file -FilePath '.\nginx\html\main.html' -Append -Force
    '    document.getElementById("size").innerHTML=selectedGameInfo[5];'|out-file -FilePath '.\nginx\html\main.html' -Append -Force
    '});'|out-file -FilePath '.\nginx\html\main.html' -Append -Force
    '});'|out-file -FilePath '.\nginx\html\main.html' -Append -Force
    '</script>'|out-file -FilePath '.\nginx\html\main.html' -Append -Force

    #Yay for a crappy favion
    '<link rel="shortcut icon" type="image/png" href="./images/favicon.png"/>'|out-file -FilePath '.\nginx\html\main.html' -Append -Force
    '</head>'|out-file -FilePath '.\nginx\html\main.html' -Append -Force

    



    #get the list of game files with all details
    $3dsCiafiles = Get-ChildItem ".\nginx\html\cias\*" -Include *.cia
    if($3dsCiafiles.Count -gt 0 )
    {        
        #add some styling for the main page area
        #'<style> .content {position: absolute;top: 30%;}'|out-file -FilePath '.\nginx\html\main.html' -Append -Force
        '<style> .content {max-width: 1000px;margin: auto;}'|out-file -FilePath '.\nginx\html\main.html' -Append -Force
        'table.greyGridTable {'|out-file -FilePath '.\nginx\html\main.html' -Append -Force
        '  font-family: "Lucida Sans Unicode", "Lucida Grande", sans-serif;'|out-file -FilePath '.\nginx\html\main.html' -Append -Force
        'background-color: #FFFFFF;'|out-file -FilePath '.\nginx\html\main.html' -Append -Force
        '  width: 100%;'|out-file -FilePath '.\nginx\html\main.html' -Append -Force
        '  text-align: center;'|out-file -FilePath '.\nginx\html\main.html' -Append -Force
        '  border-collapse: collapse;'|out-file -FilePath '.\nginx\html\main.html' -Append -Force
        '}'|out-file -FilePath '.\nginx\html\main.html' -Append -Force
        'table.greyGridTable td, table.greyGridTable th {'|out-file -FilePath '.\nginx\html\main.html' -Append -Force
        '  border: 1px solid #FFFFFF;'|out-file -FilePath '.\nginx\html\main.html' -Append -Force
        '  padding: 3px 4px;'|out-file -FilePath '.\nginx\html\main.html' -Append -Force
        '}'|out-file -FilePath '.\nginx\html\main.html' -Append -Force
        'table.greyGridTable tbody td {'|out-file -FilePath '.\nginx\html\main.html' -Append -Force
        '  font-size: 13px;'|out-file -FilePath '.\nginx\html\main.html' -Append -Force
        '  color: #333333;'|out-file -FilePath '.\nginx\html\main.html' -Append -Force
        '}'|out-file -FilePath '.\nginx\html\main.html' -Append -Force
        'table.greyGridTable td:nth-child(even) {'|out-file -FilePath '.\nginx\html\main.html' -Append -Force
        '  background: #EBEBEB;'|out-file -FilePath '.\nginx\html\main.html' -Append -Force
        '}'|out-file -FilePath '.\nginx\html\main.html' -Append -Force
        'table.greyGridTable thead {'|out-file -FilePath '.\nginx\html\main.html' -Append -Force
        '  background: #FFFFFF;'|out-file -FilePath '.\nginx\html\main.html' -Append -Force
        '  border-bottom: 4px solid #333333;'|out-file -FilePath '.\nginx\html\main.html' -Append -Force
        '}'|out-file -FilePath '.\nginx\html\main.html' -Append -Force
        'table.greyGridTable thead th {'|out-file -FilePath '.\nginx\html\main.html' -Append -Force
        '  font-size: 15px;'|out-file -FilePath '.\nginx\html\main.html' -Append -Force
        '  font-weight: bold;'|out-file -FilePath '.\nginx\html\main.html' -Append -Force
        '  color: #333333;'|out-file -FilePath '.\nginx\html\main.html' -Append -Force
        '  text-align: center;'|out-file -FilePath '.\nginx\html\main.html' -Append -Force
        '}'|out-file -FilePath '.\nginx\html\main.html' -Append -Force
        'table.greyGridTable tfoot {'|out-file -FilePath '.\nginx\html\main.html' -Append -Force
        '  font-size: 14px;'|out-file -FilePath '.\nginx\html\main.html' -Append -Force
        '  font-weight: bold;'|out-file -FilePath '.\nginx\html\main.html' -Append -Force
        '  color: #333333;'|out-file -FilePath '.\nginx\html\main.html' -Append -Force
        '  border-top: 4px solid #333333;'|out-file -FilePath '.\nginx\html\main.html' -Append -Force
        '}'|out-file -FilePath '.\nginx\html\main.html' -Append -Force
        'table.greyGridTable tfoot td {'|out-file -FilePath '.\nginx\html\main.html' -Append -Force
        '  font-size: 14px;'|out-file -FilePath '.\nginx\html\main.html' -Append -Force
        '}'|out-file -FilePath '.\nginx\html\main.html' -Append -Force
               
               
               
               
                
        #.centered { position: fixed;  top: 50%;  left: 50%; }' |out-file -FilePath '.\nginx\html\main.html' -Append -Force       
        '</style>'|out-file -FilePath '.\nginx\html\main.html' -Append -Force
        
        #yay a background, thanks to Thanks to Pixabay for the background image on pexels (free use) - https://www.pexels.com/photo/macro-photography-of-mario-and-luigi-plastic-toy-163157/
        ('<body style="background: #D0E4F5 url(''./images/{0}'') no-repeat local 0 0;background-size:cover">' -f $backgroundPath)|out-file -FilePath '.\nginx\html\main.html' -Append -Force
        '<div class="content" background="white">' | out-file -FilePath '.\nginx\html\main.html' -Append -Force

        #quick to rebuild so, the time loss isn't too bad...if things extend maybe we add a "file check, if older than X days" part
        Write-OutLog -message ('Creating main page, found {0} game files' -f $3dsCiafiles.Count)
        
        #hacky way to move the content area down a few rows....smarter web designers welcome to fix :D
        '<p>&nbsp;</p><p>&nbsp;</p>'| out-file -FilePath '.\nginx\html\main.html' -Append -Force

        #kinda looks likes something from homebrew channel lol...
        '<div align="center" style="color: #FFFFFF;font-family:sans-serf;background: #0e8dbc;font-size:60px;font-weight:bold;text-shadow: 0 1px 0 #CCCCCC, 0 2px 0 #c9c9c9, 0 3px 0 #bbb, 0 4px 0 #b9b9b9, 0 5px 0 #aaa, 0 6px 1px rgba(0,0,0,.1), 0 0 5px rgba(0,0,0,.1), 0 1px 3px rgba(0,0,0,.3), 0 3px 5px rgba(0,0,0,.2), 0 5px 10px rgba(0,0,0,.25), 0 10px 10px rgba(0,0,0,.2), 0 20px 20px rgba(0,0,0,.15);">miiShop</div>'| out-file -FilePath '.\nginx\html\main.html' -Append -Force
        '<div style="background-color:rgba(255, 255, 255, 0.75);">'|out-file -FilePath '.\nginx\html\main.html' -Append -Force

        #Ugg...Title, or no title, I say not right now...
        #'<br>&nbsp;</br><p><h1>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Library</h1></p>'| out-file -FilePath '.\nginx\html\main.html' -Append -Force
        
        
        #Here's the tables (gulp, not divs) for the game list, game info, boxart and QR code
        '<table style="width: 100%;padding: 30px;">'| out-file -FilePath '.\nginx\html\main.html' -Append -Force
        '<tr><td width=60%>'| out-file -FilePath '.\nginx\html\main.html' -Append -Force
        '<select class="games" size="20" style="width:80%">' | out-file -FilePath '.\nginx\html\main.html' -Append -Force
        '<option value="data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7|None|None|None|./images/test.jpg "> None</option>'| out-file -FilePath '.\nginx\html\main.html' -Append -Force  

        
        Write-OutLog -message 'Checking for gameinfo and boxart (this can take a bit)'
        $gameCount=0
        foreach($3dsCiafile in $3dsCiafiles)
        {               
            #Make game names display in the list as more readable, and removing our reformatting.  
            $gameDisplayName = get-CleanGamename($3dsCiafile.name)            
            Write-OutLog -message ('Making QR code for {0}' -f $gameDisplayName)
            $url = [uri]::EscapeDataString(('http://{0}:{1}/cias/{2}' -f $myIP,$port,$3dsCiafile.name))   
            $fullQRPath=('{0}/nginx/html/qr/{1}.png' -f $PSScriptRoot,$3dsCiafile.name)
            New-QR -Message $url $fullQRPath |out-null
            $gameCount++
            Write-OutLog -message ('Searching Game info, and box art for {0} ({1} of {2})' -f $gameDisplayName,$gameCount,$3dsCiafiles.Length )
            $gameQR = ('./qr/{0}.png' -f $3dsCiafile.name)            
            
            #Build Game info
            $dbMatch='0'
            $name=$gameDisplayName
            $gameSize = '0.00MB'
            $sizeLabel ='MB'
            try
            {
                $number=Convert-Size $3dsCiafile.length -from Bytes -to MB
                if($number -ge 1000)
                {
                    $number=Convert-Size $3dsCiafile.length -from Bytes -to GB
                    $sizeLabel='GB'
                }
                elseif($number -lt 1)
                {                    
                    $number=Convert-Size $3dsCiafile.length -from Bytes -to KB
                    $sizeLabel='KB'
                }
                $gameSize = ('{0}{1}' -f [math]::round($number,2),$sizeLabel)
            }
            catch
            {
                $gameSize =  '0.00MB'
            }
            
            if ($gameDB.ToLower() -eq 'community.xml')
            {
                #load XML file
                [xml]$XmlDocument=Get-Content -Path "..\database\community.xml"
                foreach($game in $XmlDocument.database.Ticket)
                {
                    #break up name for a like search, take care of catch characters or keywords 
                    $searchName = $gameDisplayName                   
                    $searchName = $gameDisplayName.trim()
                    $searchName = $searchName.replace('  ',' ')
                    $searchName = $searchName.replace('  ',' ')
                    $searchName = $searchName.replace(' ','*' )             
                    $searchName = $searchName.replace('*-*','*')
                    $searchName = $searchName.replace('-','*')
                    $searchName = $searchName.replace('.','*')
                    $searchName = $searchName.replace('&','&amp;')
                    $searchName = $searchName.replace('*and*','*')
                    $searchName = $searchName.replace('**','*')
                    $searchName = $searchName.replace('**','*')
                    $searchName = $searchName.replace('**','*')
                    #Write-OutLog -message $searchName
                    if (($game.name -like ('*{0}*'-f $searchName )) -and (!$game.Name.Contains("DEMO")))
                    {
                        $name=$game.name
                        $publisher=$game.region
                        $serial=$game.serial
                        $code,$mid,$imgFile=$game.serial.split('-') 
                        if($debug -eq 1)
                        {
                            Write-OutLog -message ('Game information for {0}' -f $game.name)
                            Write-OutLog -message "code: $code, mid: $mid, imageFile: $imgFile"
                        }                  
                        $dbMatch='found'
                        break
                    }
                }
            }
            else
            {                    
                [xml]$XmlDocument=Get-Content -Path "..\database\3dsreleases.xml"
                foreach($game in $XmlDocument.releases.release)
                {
                    #break up name for a like search, take care of catch characters or keywords
                    $searchName = $gameDisplayName.trim()
                    $searchName = $searchName.replace('  ',' ')
                    $searchName = $searchName.replace('  ',' ')
                    $searchName = $searchName.replace(' ','*' )                
                    $searchName = $searchName.replace('*-*','*')
                    $searchName = $searchName.replace('-','*')
                    $searchName = $searchName.replace('.','*')
                    $searchName = $searchName.replace('&','&amp;')
                    $searchName = $searchName.replace('*and*','*')
                    $searchName = $searchName.replace('**','*')
                    $searchName = $searchName.replace('**','*')
                    $searchName = $searchName.replace('**','*')
                    $searchName = $searchName.replace('**','*')
                    #Write-OutLog -message $searchName
                    if (($game.name -like ('*{0}*'-f $searchName )) -and (!$game.Name.Contains("DEMO")))
                    {
                        $name=$game.name
                        $publisher=$game.publisher
                        $serial=$game.serial
                        $code,$imgFile=$game.serial.split('-')                   
                        $dbMatch='found'
                        break
                    }
                } 
            }
            if($dbMatch.ToLower() -eq 'found')
            {
                    
                #Match to see if we can find the optimal link for showing the image, in future store this somewhere
                $imgFiles = @()
                $imgFiles = ("https://art.gametdb.com/3ds/coverHQ/US/$imgFile.jpg", "https://art.gametdb.com/3ds/coverHQ/EN/$imgFile.jpg","https://art.gametdb.com/3ds/coverHQ/other/$imgFile.jpg","https://art.gametdb.com/3ds/coverHQ/NL/$imgFile.jpg",,"https://art.gametdb.com/3ds/coverHQ/RU/$imgFile.jpg",,"https://art.gametdb.com/3ds/coverHQ/FR/$imgFile.jpg","https://art.gametdb.com/3ds/coverHQ/DE/$imgFile.jpg","https://art.gametdb.com/3ds/coverHQ/ES/$imgFile.jpg","https://art.gametdb.com/3ds/coverHQ/JA/$imgFile.jpg", "https://art.gametdb.com/3ds/coverHQ/PT/$imgFile.jpg" )
                $bestMatch = ''
                    
                foreach ($imgFile in $imgFiles)
                {
                    try
                    {
                        if(invoke-webrequest $imgFile -DisableKeepAlive -UseBasicParsing -Method head)
                        {
                            $bestMatch = ''
                            $bestMatch=$imgFile
                            break
                        }

                    }
                    catch
                    {

                    }
                }
                #If we match use the name and image we match with, if not use scrubbed game name, and test image
                if($bestMatch -ne '')
                {
                    $gameValue=('{0}|{1}|{2}|{3}|{4}|{5}'-f $gameQR,$name.trim(),$publisher,$serial,$bestMatch,$gameSize)
                }
                else
                {
                    $gameValue=('{0}|{1}|{2}|{3}|./images/test.jpg|{4}'-f $gameQR,$name.trim(),$publisher,$serial,$gameSize)
                }
            }      
            else
            {
                
                Write-OutLog -message ('No match found for {0}' -f $name.trim())
                Write-OutLog -message ''
                $gameValue=("{0}|{1}|Unknown|Unknown|'./images/test.jpg'|{2}"-f $gameQR,$gameDisplayName,$gameSize)
            }                      
            #Add QR codes to the values
            ('<option value="{0}">{1}</option>' -f $gameValue ,$name ) | out-file -FilePath '.\nginx\html\main.html' -Append -Force            
        }
        
        #thanks for the fake boxart found here - https://imgur.com/4AxEWvV
        #Thanks so much to W3schools for teaching me so much about styling (yeah I should use style sheets or something, I get it...)
        
        '</select></td> <td id="imgBoxArt" align="center" style="border: 30px solid #DFE7EA;border-radius: 15px 15px 15px 15px;background: white url(./images/test.jpg); width:40%;background-size: 100% 100%; background-repeat: no-repeat;">'| out-file -FilePath '.\nginx\html\main.html' -Append -Force

        #Cool trick to make a 1x1 pixel image from a base64 encoded gif,no file necessary..this is nuts folks...full credit ->https://css-tricks.com/snippets/html/base64-encode-of-1x1px-transparent-gif/
        '<img id="qr" src="data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7">' | out-file -FilePath '.\nginx\html\main.html' -Append -Force
        '</td> </tr>'| out-file -FilePath '.\nginx\html\main.html' -Append -Force    
        
        #hey, doesn't this kinda look like a 3DS game?  Well it kinda does...it's pretty cool
        '<tr><td background="white" style="width: 40%">'| out-file -FilePath '.\nginx\html\main.html' -Append -Force       

        #Game info displayed here, receive info in javascript above
        '<table style="width: 420px" class="greyGridTable">'| out-file -FilePath '.\nginx\html\main.html' -Append -Force
        '<tbody>'| out-file -FilePath '.\nginx\html\main.html' -Append -Force
        '<tr>'| out-file -FilePath '.\nginx\html\main.html' -Append -Force
        '<thead>'| out-file -FilePath '.\nginx\html\main.html' -Append -Force
        '<th width="30%">&nbsp;Name&nbsp;</td>'| out-file -FilePath '.\nginx\html\main.html' -Append -Force
        if($gameDB -eq 'community.xml')
        {
            '<th width="30%">&nbsp;Region&nbsp;</td>'| out-file -FilePath '.\nginx\html\main.html' -Append -Force
        }
        else
        {
            '<th width="30%">&nbsp;Publisher&nbsp;</td>'| out-file -FilePath '.\nginx\html\main.html' -Append -Force        
        }        
        '<th width="30%">&nbsp;Serial&nbsp;</td>'| out-file -FilePath '.\nginx\html\main.html' -Append -Force
        '<th width="30%">&nbsp;Size&nbsp;</td>'| out-file -FilePath '.\nginx\html\main.html' -Append -Force
        '</thead>'| out-file -FilePath '.\nginx\html\main.html' -Append -Force
        '</tr>'| out-file -FilePath '.\nginx\html\main.html' -Append -Force
        '<tr>'| out-file -FilePath '.\nginx\html\main.html' -Append -Force
        '<td width="30%" id="name">&nbsp;</td>'| out-file -FilePath '.\nginx\html\main.html' -Append -Force
        '<td width="30%" id="publisher">&nbsp;</td>'| out-file -FilePath '.\nginx\html\main.html' -Append -Force
        '<td width="30%" id="serial">&nbsp;</td>'| out-file -FilePath '.\nginx\html\main.html' -Append -Force
        '<td width="30%" id="size">&nbsp;</td>'| out-file -FilePath '.\nginx\html\main.html' -Append -Force
        '</tr>'| out-file -FilePath '.\nginx\html\main.html' -Append -Force
        '</tbody>'| out-file -FilePath '.\nginx\html\main.html' -Append -Force
        '</table>'| out-file -FilePath '.\nginx\html\main.html' -Append -Force



        '</table>'| out-file -FilePath '.\nginx\html\main.html' -Append -Force    
        
        #closing out time!
        
        '</div>' | out-file -FilePath '.\nginx\html\main.html' -Append -Force  
        '<br><br>' | out-file -FilePath '.\nginx\html\main.html' -Append -Force
     }   
     '</div>' |out-file -FilePath '.\nginx\html\main.html' -Append -Force
     '</body>'|out-file -FilePath '.\nginx\html\main.html' -Append -Force
     '</html>'|out-file -FilePath '.\nginx\html\main.html' -Append -Force  
}

function get-cias
{
    # Get all Cia's in the game directory
    $fileType='*.cia'
    $ciafiles = Get-ChildItem "..\*" -Include $fileType
    if($ciafiles.Count -gt 0 )
    {    
        #Move, Sanatize and sort the games
        Write-OutLog -message ('Starting processing, found {0} {1} files' -f $ciafiles.Count,$fileType)    
        foreach ($ciafile in $ciafiles)
        {        
            #move games to the cias directory
            Move-Item -Path $ciafile.FullName -Destination '.\nginx\html\cias\'     
            $newFileLocation = ('.\nginx\html\cias\{0}' -f $ciafile.Name)
            $newname = $ciafile.Name.replace(' ','_')
            $newname = $newname.replace("'","")
            $newname = $newname.replace('[','')
            $newname = $newname.replace(']','')
            #Clean up game name for proper link building based on what FBI can read
            $fullNewName = (Resolve-Path ('.\nginx\html\cias\{0}' -f $newname)).Path
            $fullFilePath= (resolve-path $newFileLocation).Path     

            rename-item -NewName $fullNewName -Path $fullFilePath
        }
    }
    else
    {
        #errors with processing a file, skip it
        Write-OutLog -message ('Continuing, found {0} new {1} files' -f $ciafiles.Count,$fileType)
    }
}

function start-makingpage
{    
    Set-Location $PSScriptRoot
    if(test-path '.\nginx')
    {
        #$settingsPath=('{0}\database\settings.csv' -f (get-item $PSScriptRoot).Parent.FullName)
        $settings = get-settings 
        #For future use
        <# 
        $port=$settings.Where({$PSItem.Name -eq 'port'}).Value
        $debug=$settings.Where({$PSItem.Name -eq 'debug'}).Value
        $gamePath=$settings.Where({$PSItem.Name -eq 'gamePath'}).Value
        append images path, this way the user just supplies the image file 
        #>
        $backgroundPath =('./images/{0}' -f $settings.Where({$PSItem.Name -eq 'backgroundPath'}).Value)
        $gameDB = $settings.Where({$PSItem.Name -eq 'gameDB'}).Value

        #making folders with my make folder if doesn't exist function
        write-outlog -message 'Creating folders as needed and populating data'
        checkmake-folder -folderName "..\logs"
        checkmake-folder -folderName ".\nginx\html\cias"
        checkmake-folder -folderName ".\nginx\html\qr"
        checkmake-folder -folderName ".\nginx\html\images"
        checkmake-folder -folderName "..\database"
        checkmake-folder -folderName "..\backup"
        Copy-Item '..\images\*.*' '.\nginx\html\images'

        Write-OutLog -message 'Obtaining Local IP'
        $myIPaddy='127.0.0.1'
        $myIPaddy = @(@(Get-WmiObject Win32_NetworkAdapterConfiguration | Select-Object -ExpandProperty IPAddress) -like "*.*")[0].ToString().Trim()
        get-cias -ipAddress $myIPaddy

        #Download 3ds game database, to ensure we have it
        if($gameDB.ToLower() -eq 'community.xml')
        {
            Invoke-WebRequest -uri 'http://ptrk25.github.io/GroovyFX/database/community.xml'-OutFile "..\database\$gameDB"
        } 
        else
        {
            Invoke-WebRequest -uri 'http://3dsdb.com/xml.php'-OutFile "..\database\$gameDB"
        }
        #make or remake the main page
        make-mainpage -myIP $myIPaddy -backgroundPath $backgroundPath
    }
    else
    {
        Write-OutLog -message 'Please run the webserver install prior to making the main page'
    }
    Write-OutLog -message 'Completed making main page. Start miiShop to view your library'
}

############################################## end functions
############################################## Launch Form
$Form.Add_Shown({$Form.Activate()})
[void] $Form.ShowDialog()