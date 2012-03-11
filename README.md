EMUlaunch
=========

A front-end application used for launching games on popular emulators on the Mac

How EMUlaunch is built
----------------------

EMUlaunch is primarily written in ActionScript 2 with some AppleScript/PHP. It is compiled into a native Macintosh app using MProjector. http://www.screentime.com/software/flash-projector

Mprojector uses its own actionscript syntax to create native OS X menu and file dialogs within EMUlaunch. 

Disclaimer
----------

The EMUlaunch source code was originally written as pet project back in 2003 back when I was first starting ActionScript. That being said the code suffers from some obvious beginner decisions and limitations found in ActionScript 1 which was then converted into AS2. From what I remember the most basic workflow of how EMUlaunch works is this:

1. User sets the paths for their emulators/roms/screenshots from within the Application.
2. EMUlaunch creates xml files with these paths and other settings such as screen size and layout choices.
3. Since MAME game files use short names, EMUlaunch creates a php file to compare each of the users rom files with the MAME generated listxml.xml file bundled with EMUlaunch.

I can't really offer any support for this project and am only releasing this for those who have shown interest in EMUlaunch. For those truly interested in helping on a native Mac EMU frontend client I suggest you look into OpenEmu https://github.com/OpenEmu/OpenEmu