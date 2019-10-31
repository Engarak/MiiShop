# MiiShop
It's a PC based management system and library for legal backups of your 3DS software, with functions to reinstall your 3DS software via QR codes you can scan in FBI. (thanks /u/Level44EnderShaman on reddit! Much better description)

## Screenshots
miiShop v0.2.9 - SO MUCH EASIER TO USE!
![miiShop v0.2.9 - Button driven menu](https://i.imgur.com/aZoAOHv.jpg)
![miiShop v0.2.9 - Logging windows](https://i.imgur.com/8jTIO0m.jpg)
![miiShop v0.2.9 - In app settings configuration](https://i.imgur.com/UtQ0Gcr.jpg)
![miiShop v0.2.9 - Automated Updater](https://i.imgur.com/AVqxmu7.jpg)
miiShop v0.2.5 - Box Art and Game Info, I'm overly excited for this!
![miiShop v0.2.5 - Box Art and Game Info!](https://i.imgur.com/OBuEPXW.jpg "miiShop v0.2.5")
miiShop v0.2 UI - A real UI!
![miiShop v0.2 UI](https://i.imgur.com/64eoQnD.png "miiShop v0.2 UI")

## What's new? What's different?
+ Split up miiShop into multiple modules, making way for...
+ Added a new UI for all the parts of miiShop, for ease of working with miiShop
+ Updated the read.md file to reflect the new changes
+ Updated the webserver (hopefully for the last time) to NGINX - https://nginx.org
+ Added in an update function, so when a new update to a module is released, it can be installed right away
+ Be aware your 3DS software will move in a few directories deepr.  Due to how the webserver is configured to work, they will be found in the /bin/nginx/html/cias folder.
+ 
+ More flexability of what is run when with a button driven menu system, so you choose to run what you want and when

## Upgrade/Install Instructions
1. New upgrade process, check here for directions -> https://github.com/Engarak/miiShop_Install/releases 

## Known Issues

+ Errors with special characters when processing library - At times  when processing games it will toss an error on the specific game.  Open an issue and get me the error message I'll try to catch the case in a future version.
+ ~~Console is displayed when start.bat is ran - For now I haven't set this it to start up miznimized, but that's in the plan.  However, you can minimze the window yourself.~~
  + Console is no longer displayed, and most powershell/console windows are hidden (though some may flash up for a second)
+ Some QR codes won't work - FBI has some requirements around links I'm discovering manually as I haven't seen a list spelled out, but I haven't asked for one either.  This ties into the errors with special characters issue listed above mostly, as these also break URL conventions.  I try to fix most files for this, however I haven't caught all cases.
+ Game matching is fuzzy, and slower (~1 file a second).  Looking to improve this greatly
  + In 0.2.9, this is much less of an issue.  You choose when to rebuild your main page, so this only impacts you when you choose it to.
  + This still is on my radar to fix, just not as pressing
