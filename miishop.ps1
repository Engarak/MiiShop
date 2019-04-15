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


#This is the function that buils the QR codes, renames the game files and probably get boxart/game info...maybe
function get-cias  ([string] $ipAddress)
{
    # Get all Cia's in the game directory
    $fileType='*.cia'
    $ciafiles = Get-ChildItem "$PSScriptRoot\*" -Include $fileType
    if($ciafiles.Count -gt 0 )
    {    
        #Move, Sanatize and sort the games
        Write-Output ('{2} Starting processing, found {0} {1} files' -f $ciafiles.Count,$fileType,$(Get-Date -Format s))    
        foreach ($ciafile in $ciafiles)
        {        
            #move games to the cias directory
            Move-Item -Path $ciafile.FullName -Destination "$PSScriptRoot\cias\"     
            $newFileLocation = ('{0}\cias\{1}' -f $PSScriptRoot,$ciafile.Name)
            $newname = $ciafile.Name.replace(' ','_')
            $newname = $newname.replace("'","")
            $newname = $newname.replace('[','')
            $newname = $newname.replace(']','')
            #Clean up game name for proper link building based on what FBI can read
            rename-item -NewName (('{0}\cias\{1}' -f $PSScriptRoot,$newname)) -Path $newFileLocation
            Write-Output ('{0} Making QR code for {1}' -f $(Get-Date -Format s),$newname)
            New-QR -Message ('http://{0}:8080/cias/{1}' -f $ipAddress,$newname) -fileName ('{0}\qr\{1}.png' -f $PSScriptRoot,$newname)|out-null
        }
    }
    else
    {
        #errors with processing a file, skip it
        Write-Output ('{2} Continuing, found {0} new {1} files' -f $ciafiles.Count,$fileType,$(Get-Date -Format s))
    }
}

function checkmake-folder ([string] $folderName)
{
    #Just had to create some folders, and wanted to test if they existed first, this was to save 10 lines of code...worth it?
    if(!(test-path $folderName))
    {
        New-Item -ItemType Directory -Force -Path $folderName
    }

}

function make-mainpage ([string] $myIP)
{
    #There probably is a better way, but html is forviging, so writing to a .html file as a text file, with correct tags but probably poor formatting

    
    #Rebuild page every time, so when I add custom background support it's easier to allow
    Write-Output ('{0} Making Index Page' -f $(Get-Date -Format s))
    '<html>'|out-file -FilePath ('{0}\main.html' -f $PSScriptRoot) -Force
    '<head>'|out-file -FilePath ('{0}\main.html' -f $PSScriptRoot) -Append -Force
    '<title>3DS Game Directory</title>'|out-file -FilePath ('{0}\main.html' -f $PSScriptRoot) -Append -Force

    #This is for changing the images for boxart and QR code without a page reload, just a reload of those images
    '<script src="https://code.jquery.com/jquery-1.12.4.min.js"></script>'|out-file -FilePath ('{0}\main.html' -f $PSScriptRoot) -Append -Force
    '<script type="text/javascript">'|out-file -FilePath ('{0}\main.html' -f $PSScriptRoot) -Append -Force
    '$(document).ready(function(){'|out-file -FilePath ('{0}\main.html' -f $PSScriptRoot) -Append -Force
    '$("select.games").change(function(){'|out-file -FilePath ('{0}\main.html' -f $PSScriptRoot) -Append -Force
    'var selectedGame = $(this).children("option:selected").val();'|out-file -FilePath ('{0}\main.html' -f $PSScriptRoot) -Append -Force
    '    document.getElementById("qr").src=selectedGame'|out-file -FilePath ('{0}\main.html' -f $PSScriptRoot) -Append -Force
    '});'|out-file -FilePath ('{0}\main.html' -f $PSScriptRoot) -Append -Force
    '});'|out-file -FilePath ('{0}\main.html' -f $PSScriptRoot) -Append -Force
    '</script>'|out-file -FilePath ('{0}\main.html' -f $PSScriptRoot) -Append -Force

    #Yay for a crappy favion
    '<link rel="shortcut icon" type="image/png" href="/images/favicon.png"/>'|out-file -FilePath ('{0}\main.html' -f $PSScriptRoot) -Append -Force
    '</head>'|out-file -FilePath ('{0}\main.html' -f $PSScriptRoot) -Append -Force

    #get the list of game files with all details
    $3dsCiafiles = Get-ChildItem "$PSScriptRoot\cias\*" -Include *.cia
    if($3dsCiafiles.Count -gt 0 )
    {            
        #add some styling for the main page area
        #'<style> .content {position: absolute;top: 30%;}'|out-file -FilePath ('{0}\main.html' -f $PSScriptRoot) -Append -Force

        '<style> .content {max-width: 1000px;margin: auto;}'|out-file -FilePath ('{0}\main.html' -f $PSScriptRoot) -Append -Force
        #.centered { position: fixed;  top: 50%;  left: 50%; }' |out-file -FilePath ('{0}\main.html' -f $PSScriptRoot) -Append -Force       
        '</style>'|out-file -FilePath ('{0}\main.html' -f $PSScriptRoot) -Append -Force
        
        #yay a background, thanks to Thanks to Pixabay for the background image on pexels (free use) - https://www.pexels.com/photo/macro-photography-of-mario-and-luigi-plastic-toy-163157/
        '<body style="background: #D0E4F5 url(''/images/background.jpg'') no-repeat local 0 0;background-size:cover">'|out-file -FilePath ('{0}\main.html' -f $PSScriptRoot) -Append -Force
        '<div class="content" background="white">' | out-file -FilePath ('{0}\main.html' -f $PSScriptRoot) -Append -Force

        #quick to rebuild so, the time loss isn't too bad...if things extend maybe we add a "file check, if older than X days" part
        Write-Output ('{1} Creating main page, found {0} game files' -f $3dsCiafiles.Count,$(Get-Date -Format s))   
        
        #hacky way to move the content area down a few rows....smarter web designers welcome to fix :D
        '<p>&nbsp;</p><p>&nbsp;</p>'| out-file -FilePath ('{0}\main.html' -f $PSScriptRoot) -Append -Force

        #kinda looks likes something from homebrew channel lol...
        '<div align="center" style="color: #FFFFFF;font-family:sans-serf;background: #0e8dbc;font-size:60px;font-weight:bold;text-shadow: 0 1px 0 #CCCCCC, 0 2px 0 #c9c9c9, 0 3px 0 #bbb, 0 4px 0 #b9b9b9, 0 5px 0 #aaa, 0 6px 1px rgba(0,0,0,.1), 0 0 5px rgba(0,0,0,.1), 0 1px 3px rgba(0,0,0,.3), 0 3px 5px rgba(0,0,0,.2), 0 5px 10px rgba(0,0,0,.25), 0 10px 10px rgba(0,0,0,.2), 0 20px 20px rgba(0,0,0,.15);">miiShop</div>'| out-file -FilePath ('{0}\main.html' -f $PSScriptRoot) -Append -Force
        '<div style="background-color:rgba(255, 255, 255, 0.75);">'|out-file -FilePath ('{0}\main.html' -f $PSScriptRoot) -Append -Force

        #Ugg...Title, or no title, I say not right now...
        #'<br>&nbsp;</br><p><h1>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Library</h1></p>'| out-file -FilePath ('{0}\main.html' -f $PSScriptRoot) -Append -Force
        
        


        #Here's the tables (gulp, not divs) for the game list, game info, boxart and QR code
        '<table style="width: 100%;padding: 30px;">'| out-file -FilePath ('{0}\main.html' -f $PSScriptRoot) -Append -Force
        '<tr><td>'| out-file -FilePath ('{0}\main.html' -f $PSScriptRoot) -Append -Force
        '<select class="games" size="20">' | out-file -FilePath ('{0}\main.html' -f $PSScriptRoot) -Append -Force

        foreach($3dsCiafile in $3dsCiafiles)
        {        
            #Make game names display in the list as more readable, and removing our reformatting.  This is starting to scream get a SQL lite DB or something to store this list...as it will get bigger
            $gameDisplayName = $3dsCiafile.name
            $gameQR = ('{0}.png' -f $3dsCiafile.name)
            $gameDisplayName = $gameDisplayName.replace('.cia','')
            $gameDisplayName = $gameDisplayName.replace('_',' ')
            $gameDisplayName = $gameDisplayName.replace(' US','')
            $gameDisplayName = $gameDisplayName.replace(' USA','')
            $gameDisplayName = $gameDisplayName.replace(' DEC','')
            $gameDisplayName = $gameDisplayName.replace(' EU','')
            $gameDisplayName = $gameDisplayName.replace('(US)','')
            $gameDisplayName = $gameDisplayName.replace('(EUR)','')
            $gameDisplayName = $gameDisplayName.replace('(USA)','')
            $gameDisplayName = $gameDisplayName.replace('(RF)','')            
            $gameDisplayName = $gameDisplayName.replace('EUR','')
            #Add QR codes to the values
            ('<option value="qr/{0}">{1}</option>' -f $gameQR ,$gameDisplayName ) | out-file -FilePath ('{0}\main.html' -f $PSScriptRoot) -Append -Force
        }
        #thanks for the fake boxart found here - https://imgur.com/4AxEWvV
        #Thanks so much to W3schools for teaching me so much about styling (yeah I should use style sheets or something, I get it...)
        '</td> <td align="center"  style="border: 30px solid #DFE7EA;border-radius: 15px 15px 15px 15px;background: url(/images/test.jpg); background-size: 100% 100%; background-repeat: no-repeat;">'| out-file -FilePath ('{0}\main.html' -f $PSScriptRoot) -Append -Force
        
        #oh god this hack...invisible text to keep the table a consistent width...there HAS to be a better way but...well any port in a storm currently
        '<p id="art" style="color: white;visibility: hidden;"><-------------------------------------></p>'| out-file -FilePath ('{0}\main.html' -f $PSScriptRoot) -Append -Force

        #Cool trick to make a 1x1 pixel image from a base64 encoded gif,no file necessary..this is nuts folks...full credit ->https://css-tricks.com/snippets/html/base64-encode-of-1x1px-transparent-gif/
        '<img id="qr" src="data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7">' | out-file -FilePath ('{0}\main.html' -f $PSScriptRoot) -Append -Force
        '</td> </tr>'| out-file -FilePath ('{0}\main.html' -f $PSScriptRoot) -Append -Force    
        
        #hey, doesn't this kinda look like a 3DS game?  Well it kinda does...it;s pretty cool
        '<tr><td background="white">'| out-file -FilePath ('{0}\main.html' -f $PSScriptRoot) -Append -Force            
        '<p id="info" align="center">Game info coming soon!</p>'| out-file -FilePath ('{0}\main.html' -f $PSScriptRoot) -Append -Force
        '</select>' | out-file -FilePath ('{0}\main.html' -f $PSScriptRoot) -Append -Force
        '</table>'| out-file -FilePath ('{0}\main.html' -f $PSScriptRoot) -Append -Force    
        
        #closing out time!
        
        '</div>' | out-file -FilePath ('{0}\main.html' -f $PSScriptRoot) -Append -Force  
        '<br><br>' | out-file -FilePath ('{0}\main.html' -f $PSScriptRoot) -Append -Force
     }   
     '</div>' |out-file -FilePath ('{0}\main.html' -f $PSScriptRoot) -Append -Force
     '</body>'|out-file -FilePath ('{0}\main.html' -f $PSScriptRoot) -Append -Force
     '</html>'|out-file -FilePath ('{0}\main.html' -f $PSScriptRoot) -Append -Force  
}


#get a start date, formatted for files
$dateFormat = 'M-d-y-hh_mm_ss'
$date=(get-date).ToString($dateFormat)

#making folders with my make folder if doesn't exist function
('{0} Creating folders as needed' -f $(Get-Date -Format s))
checkmake-folder -folderName "$PSScriptRoot\logs"
checkmake-folder -folderName "$PSScriptRoot\logs\web"
checkmake-folder -folderName "$PSScriptRoot\cias"
checkmake-folder -folderName "$PSScriptRoot\qr"
checkmake-folder -folderName "$PSScriptRoot\images"
checkmake-folder -folderName "$PSScriptRoot\boxart"

#Start Transcript logging for what the window says
Start-Transcript -Path ('{0}\logs\MiiShop{1}.log' -f $PSScriptRoot, $date) 

#Yay no more needing to try picking your local IP.  Seems to work for me even with a firewall
write-host ('{0} Detecting Local IP address, this may take a few seconds' -f $(Get-Date -Format s))
$myIPaddy= (
    Get-NetIPConfiguration |
    Where-Object {
        $_.IPv4DefaultGateway -ne $null -and
        $_.NetAdapter.Status -ne "Disconnected"
    }
).IPv4Address.IPAddress

('{0} Setting Webserver address to {1}' -f $(Get-Date -Format s),$myIPaddy)
('{0} Managing Data' -f $(Get-Date -Format s))
#Legacy - no need to re-activate, not using multiple child pages for games now.  Nice and neat on one page
#get-cias -ipAddress $myIPaddy

#make the main page
make-mainpage -myIP $myIPaddy

#check/make firewall rules, currently windows only, add OS check to verify if i run this or do something with firewalld on linux/mac
('{0} Adding firewalls exception if needed' -f $(Get-Date -Format s))

try
{
    #this should check if the rule exists, if it doesn't exist it will error, sending us to catch it by making the rule.  Easies way is the wrong way folks!
    Get-NetFirewallRule -DisplayName 'MiiShop Web port - In' -ErrorAction SilentlyContinue | Out-Null
    ('{0} Inbound rule already exists, skipping' -f $(Get-Date -Format s))
}
catch
{
    #Add in rule for local network
    netsh advfirewall firewall add rule name="MiiShop Web port - In" dir=in action=allow protocol=TCP localport=8080 | Out-Null
}
try
{
    #Copy-paste - this should check if the rule exists, if it doesn't exist it will error, sending us to catch it by making the rule.  Easies way is the wrong way folks!
    Get-NetFirewallRule -DisplayName 'MiiShop Web port - Out'  -ErrorAction SilentlyContinue | Out-Null
    ('{0} Outbound rule already exists, skipping' -f $(Get-Date -Format s))
}
catch
{
    #Add in rule for local network
    netsh advfirewall firewall add rule name="MiiShop Web port - Out" dir=out action=allow protocol=TCP localport=8080 | Out-Null
}


#Build local server URL
$serverURL=('http://{0}:8080/main.html' -f $myIPaddy)

#legacy web server that wasn't made for this use, don't use unless you REALLY want issues
#$scriptPath = ('{0}\Start-WebServer.ps1' -f $PSScriptRoot)
#$argumentList = ('"http://{0}:8080/"' -f $myIPaddy)


#PoSHServer made as a more robust powershell webserver, and more extensable
$scriptPath = ('{0}\PoSHServer-Standalone.ps1' -f $PSScriptRoot)
$argumentList = ('-IP {0} -Port 8080 -HomeDirectory "{1}" -LogDirectory "{1}\logs\web"' -f $myIPaddy,$PSScriptRoot)
write-output -InputObject $scriptPath
write-output -inputobject $argumentList

#lets kick some tires, and light some fires, it's web server time!
Invoke-Expression "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe $scriptPath $argumentList"

#well crud, I shouldn't try local client browser launch... these lines will be deleted next upload
#('{0} Opening your browser to {1} to see the game list' -f $(Get-Date -Format s),$myIPaddy)
#& $serverURL

#When the script is stopped, or the web server crashes, stop logging.  This should catch the error inthe log!
Stop-Transcript