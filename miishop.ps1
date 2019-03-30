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
        try {$res = $req.GetResponse()} catch {Write-host $URL; Write-error $error[0]; break} 
       
 
       
        # Save downloaded binary file    
        if($res.StatusCode -eq 200)  
        { 
            $reader = $res.GetResponseStream() 
            try {$writer = new-object System.IO.FileStream $fileName, "Create"}catch{Write-host "Invalid File Path?"; break} 
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

function get-cias  ([string] $ipAddress)
{
    $fileType='*.cia'
    $ciafiles = Get-ChildItem "$PSScriptRoot\*" -Include $fileType
    if($ciafiles.Count -gt 0 )
    {    
        Write-Output ('{2} Starting processing, found {0} {1} files' -f $ciafiles.Count,$fileType,$(Get-Date -Format s))    
        foreach ($ciafile in $ciafiles)
        {        
            Move-Item -Path $ciafile.FullName -Destination "$PSScriptRoot\cias\"     
            $newFileLocation = ('{0}\cias\{1}' -f $PSScriptRoot,$ciafile.Name)
            $newname = $ciafile.Name.replace(' ','_')
            $newname = $newname.replace("'","")
            $newname = $newname.replace('[','')
            $newname = $newname.replace(']','')
            rename-item -NewName (('{0}\cias\{1}' -f $PSScriptRoot,$newname)) -Path $newFileLocation
            Write-Output ('{0} Making QR code for {1}' -f $(Get-Date -Format s),$newname)
            New-QR -Message ('http://{0}:8080/cias/{1}' -f $ipAddress,$newname) -fileName ('{0}\qr\{1}.png' -f $PSScriptRoot,$newname)|out-null
            '<html>'|out-file -FilePath ('{0}\html\3ds_{1}.html' -f $PSScriptRoot,$newname) -Force
            '<header>'|out-file -FilePath ('{0}\html\3ds_{1}.html' -f $PSScriptRoot,$newname) -Append -Force
            ('<title>Game QR code - {0}</title>' -f $newname)|out-file -FilePath ('{0}\html\3ds_{1}.html' -f $PSScriptRoot,$newname) -Append -Force
            '</header>'|out-file -FilePath ('{0}\html\3ds_{1}.html' -f $PSScriptRoot,$newname) -Append -Force
            '<body>'|out-file -FilePath ('{0}\html\3ds_{1}.html' -f $PSScriptRoot,$newname) -Append -Force
            ('<h1>{0}</h1>' -f $ciafile.Name) | out-file -FilePath ('{0}\html\3ds_{1}.html' -f $PSScriptRoot,$newname) -Append -Force
            ('<img src="../qr/{1}.png" />'-f $ipAddress,$ciafile.Name)|out-file -FilePath ('{0}\html\3ds_{1}.html' -f $PSScriptRoot,$newname) -Append -Force
            #('<img src="{0}" style="border: none; height: 85%;" />'-f $newFileLocation)|out-file -FilePath ('{0}\html\3ds_{1}.html' -f $PSScriptRoot,$ciafile.Name) -Append -Force
            '</body>'|out-file -FilePath ('{0}\html\3ds_{1}.html' -f $PSScriptRoot,$newname) -Append -Force
            '</html>'|out-file -FilePath ('{0}\html\3ds_{1}.html' -f $PSScriptRoot,$newname) -Append -Force
        }
    }
    else
    {
        Write-Output ('{2} Continuing, found {0} new {1} files' -f $ciafiles.Count,$fileType,$(Get-Date -Format s))
    }
}

function checkmake-folder ([string] $folderName)
{
    if(!(test-path $folderName))
    {
        New-Item -ItemType Directory -Force -Path $folderName
    }

}

function make-mainpage
{
    Write-Output ('{0} Making Index Page' -f $(Get-Date -Format s))
    '<html>'|out-file -FilePath ('{0}\main.html' -f $PSScriptRoot) -Force
    '<header>'|out-file -FilePath ('{0}\main.html' -f $PSScriptRoot) -Append -Force
    '<title>3DS Game Directory</title>'|out-file -FilePath ('{0}\main.html' -f $PSScriptRoot) -Append -Force
    '</header>'|out-file -FilePath ('{0}\main.html' -f $PSScriptRoot) -Append -Force
    '<body>'|out-file -FilePath ('{0}\main.html' -f $PSScriptRoot) -Append -Force
    $3dshtmlfiles = Get-ChildItem "$PSScriptRoot\html\*" -Include 3ds*.html
    if($3dshtmlfiles.Count -gt 0 )
    {            
    
        '<body>'|out-file -FilePath ('{0}\main.html' -f $PSScriptRoot) -Append -Force
        Write-Output ('{1} Creating main page, found {0} HTML files' -f $3dshtmlfiles.Count,$(Get-Date -Format s))   
        '<h1>3DS Games</h1><br>'| out-file -FilePath ('{0}\main.html' -f $PSScriptRoot) -Append -Force
        foreach ($3dshtmlfile in $3dshtmlfiles)
        { 
            ('- <a href="html/{0}">{0}</a><br>'-f $3dshtmlfile.name )|out-file -FilePath ('{0}\main.html' -f $PSScriptRoot) -Append -Force
        }
     }   
     '</body>'|out-file -FilePath ('{0}\main.html' -f $PSScriptRoot) -Append -Force
     '</html>'|out-file -FilePath ('{0}\main.html' -f $PSScriptRoot) -Append -Force  
}



$dateFormat = 'M-d-y-hh_mm_ss'
$date=(get-date).ToString($dateFormat)

('{0} Creating folders as needed' -f $(Get-Date -Format s))
checkmake-folder -folderName "$PSScriptRoot\logs"
checkmake-folder -folderName "$PSScriptRoot\cias"
checkmake-folder -folderName "$PSScriptRoot\qr"
checkmake-folder -folderName "$PSScriptRoot\html"

#Start Transcript
Start-Transcript -Path ('{0}\logs\MiiShop{1}.log' -f $PSScriptRoot, $date) 
$internalIPs = get-netipaddress -AddressFamily IPv4 
Write-Output '=================Your IP Addresses================='
foreach($internalIP in $internalIPs)
{
    write-output ('ID = {0}, IP = {1}' -f $internalIP.InterfaceIndex,$internalIP.IPAddress)
} 
Write-Output '==================================================='
$userID = read-host 'Which ID is the correct one for the IP Address from your internal network?  If you are unsure, choose one that starts with 192.168.XXX.XXXX, or 10.XXX.XXX.XXX. '
try
{
    $myIP= get-netipaddress -AddressFamily IPv4 -InterfaceIndex $userID
}
catch
{
    Write-Output ('Error with selected choice, please re-start the script and try again.' -f $userID)
    break;
}
('{0} Setting Webserver address to {1}' -f $(Get-Date -Format s),$myIP.IPAddress)
('{0} Managing Data' -f $(Get-Date -Format s))
get-cias -ipAddress $myIP.IPAddress

make-mainpage

('{0} Adding firewalls exception if needed' -f $(Get-Date -Format s))
$testResults=Test-NetConnection -port 8080
if($testResults.TcpTestSuccess -eq $false)
{
    netsh advfirewall firewall add rule name="MiiShop Web port - In" dir=in action=allow protocol=TCP localport=8080 | Out-Null
    netsh advfirewall firewall add rule name="MiiShop Web port - Out" dir=out action=allow protocol=TCP localport=8080 | Out-Null
}


('{0} Open your browser to http://{1}:8080/main.html to see the game list' -f $(Get-Date -Format s),$myIP.IPAddress)

$scriptPath = ('{0}\start-webserver.ps1' -f $PSScriptRoot)
$argumentList = ('"http://{0}:8080/"' -f $myIP.IPAddress)

Invoke-Expression "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe $scriptPath $argumentList"


Stop-Transcript