# MiiShop
It's a PC based management system and library for legal backups of your 3DS software, with functions to reinstall your software via QR codes you can scan in FBI. (thanks /u/Level44EnderShaman on reddit! Much better description)
It comes with the initialization script I made that manages the library, uses PoSHServer (http://www.poshserver.net/) and uses the New-QR function taken from here (https://gallery.technet.microsoft.com/scriptcenter/f615d7e8-ed15-498d-b7cc-078377f523bf). 


## Screenshots
miiShop v0.2.5 - Box Art and Game Info, I'm overly excited for this!
![miiShop v0.2.5 - Box Art and Game Info!](https://i.imgur.com/OBuEPXW.jpg "miiShop v0.2.5")
miiShop v0.2 UI - A real UI!
![miiShop v0.2 UI](https://i.imgur.com/64eoQnD.png "miiShop v0.2 UI")


## Upgrade/Install Instructions
1. New upgrade process, check here for directions -> https://github.com/Engarak/miiShop_Install/releases 

## Known Issues

+ Errors with special characters when processing library - At times in the console when processing games it will toss an error on the specific game.  Open an issue and get me the error message I'll try to catch the case in a future version.
+ Console is displayed when start.bat is ran - For now I haven't set this it to start up miznimized, but that's in the plan.  However, you can minimze the window yourself.
+ Some QR codes won't work - FBI has some requirements around links I'm discovering manually as I haven't seen a list spelled out, but I haven't asked for one either.  This ties into the errors with special characters issue listed above mostly, as these also break URL conventions.  I try to fix most files for this, however I haven't caught all cases.
+ Game matching is fuzzy, and slower (~1 file a second).  Looking to improve this greatly
  + Well it's better in 0.2.7 by only rebuilding if there is a need (IE new games added, new settings, or can be forced).  Currently the process is actually longer in 0.2.7.


## New UI, better web design, different web server with better extensibility

+ Updated the HTML build to make a MUCH better UI (not good, but better)
+ Added a favicon.  I made it in paint, and it's terrible, but it's here for now.
+ Made all things display on one page, not multiple pages.
  + Because of this, the html folder in your game directory can be deleted if you want.  
+ Updated the read.md file to reflect the new changes
+ Added some images as well 
 + A box art placeholder (found here - https://imgur.com/4AxEWvV) 
 + a background image thanks to Pixabay (free use) https://www.pexels.com/photo/macro-photography-of-mario-and-luigi-plastic-toy-163157/
+ Updated the webserver to use PoSHServer - http://www.poshserver.net/ - License included in licenes folder - used as a standalone webserver currently, I'm looking to extend further to a more integrated one soon
+ Now we have web logs, thanks to PosHServer.  They are in the logs directory, currently in the root, soon to the web folder.  
