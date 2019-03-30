# MiiShop
Manages a basic 3DS backup file library and creates pages for each game, with QR code to reload your own games. Requires your 3DS to be altered, and able to run FBI.  It comes with the initialization script I made that manages the library, uses a basic web server taken from here (https://gallery.technet.microsoft.com/scriptcenter/Powershell-Webserver-74dcf466#content) and uses the New-QR function taken from here (https://gallery.technet.microsoft.com/scriptcenter/f615d7e8-ed15-498d-b7cc-078377f523bf). 

## Instructions
1. Download miishop.ps1, Start-WebServer.ps1, and start.bat
2. Copy all 3 files to the folder where you keep the 3DS CIAs from games you own (check your favorite serch engine how to do that)
3. Right click on start.bat and run it

## Known Issues
+ Webserver crashing - On some transferrs it seems to crash, as I didn't write the webserver I haven't been brave enough to jump in and try to fix it or switch to a different simple server
+ Errors with special characters when processing library - At times in the console when processing games it will toss an error on the specific game.  Open an issue and get me the error message I'll try to catch the case in a future version.
+ Webserver root has distructive abilities - This webserver was taken directly from the link above, where it served another process.  After I get a few more features into the MiiShop script, I'm going to remove this, and direct it to main.html
+ Console is displayed when start.bat is ran - For now I haven't set this it to start up miznimized, but that's in the plan.  However, you can minimze the window yourself
+ Some QR codes won't work - FBI has some requirements around links I'm discovering manually as I haven't seen a list spelled out, but I haven't asked for one either.  This ties into the errors with special characters issue listed above mostly, as these also break URL conventions.  I try to fix most files for this, however I haven't caught all cases.
