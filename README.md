# MiiShop
Manages a basic 3DS backup file library and creates pages for each game, with QR code to reload your own games. Requires your 3DS to be altered, and able to run FBI.  It comes with the initialization script I made that manages the library, uses PoSHServer (http://www.poshserver.net/) and uses the New-QR function taken from here (https://gallery.technet.microsoft.com/scriptcenter/f615d7e8-ed15-498d-b7cc-078377f523bf). 


## Screenshot
![miiShop v0.2 UI](https://i.imgur.com/64eoQnD.png "miiShop v0.2 UI")

## Instructions
1. Use [miiShop_install](https://github.com/Engarak/miiShop_Install/releases) to upgrade or install miiShop

## Known Issues
+ Errors with special characters when processing library - At times in the console when processing games it will toss an error on the specific game.  Open an issue and get me the error message I'll try to catch the case in a future version.
+ Console is displayed when start.bat is ran - For now I haven't set this it to start up miznimized, but that's in the plan.  However, you can minimze the window yourself
+ Some QR codes won't work - FBI has some requirements around links I'm discovering manually as I haven't seen a list spelled out, but I haven't asked for one either.  This ties into the errors with special characters issue listed above mostly, as these also break URL conventions.  I try to fix most files for this, however I haven't caught all cases.
+ Game matching is fuzzy, and slower (~1 file a second).  Looking to improve this greatly.
