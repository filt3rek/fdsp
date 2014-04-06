# FDSP

At the begining It was an experiment. I saw that the FlashDevelop browser context gives some functions that interracts with the main program. This way you can for example open a project.

You can see more informations [here](http://mromecki.fr/blog/post/flashdevelop-startpage-plugin).

It's client-server (Javascript/Neko) application using Haxe remoting that transform the **FlashDevelop Start Page** into a plugins hub.

![Screenshot 1](http://mromecki.fr/blog/post/50/fdsp_screen1.jpg)

For now it includes :
	
 * A persistent and customizable layout
 * A plugin called **fdallproj** that lists all the FD projects inside a folder (and its sub-folders)

![Screenshot 1](http://mromecki.fr/blog/post/50/fdsp_screen2.jpg)

## Installation

 * Open FlashDevelop
 * Go to the menu *Tools* --> *Program Settings*
 * Select the *Start Page* plugin (on the left panel)
 * Set *Custom Start Page* pointing to the absolute path to *bin/index.html*
 * Set *Use Custom Start Page* to *true*
 * Set your projects' root folder (path to the root of your FD projects repository) in *bin/index.html* :

		FDAllProj.showFDProjects( "c:/workspace/projects" );
	
 * Launch run.bat
 * Open the Start Page (menu "View" -> "StartPage" )
