Toxic Scripts
=============

Usage
-----
For building resources *txbuild* tool is needed. It is not included in this repository.
After *txbuild* is installed and *TXBUILD* variable is defined 

Please edit config.mak so *RESOURCES_PATH* variable specifies proper path to resources directory in your MTA installation.

Use following command for building:

Windows:

    %TXBUILD%/mingw32-make

Linux:

    make

Resources have anti-piracy protection included. When installing to destination server, serial.txt file needs to be created in txgenuine resource directory. Set its content to serial number provided with your distribution.

Some resources require multiple access right to work. Use *aclrequest allow RESOURCE all* command to make them work. For example:

    aclrequest allow txgenuine all
    aclrequest allow toxic all

List of resources depends on your distribution.

If script does not work as expected please enable debug console:

    debugscript 3

It may help you to fix configuration.

Resources
---------
clientlog - logs client errors in server console
genuine - authenticates server environments (anti-piracy protection)
include - not a resource but set of files included by other resources
mapmusic - streams maps music (after modification by /fixmapscripts command)
multiserver - adds shared global chat for multiple servers
rafalh_nametags - custom nametags rendering
rafalh_nitro - custom race_nos allowing to use nitro temporarly
rafalh_particles - snow or other particle effect depending on configuration
rafalh_shared - code used by other resources
rafalh_vip - VIP panel
rafalh_webchat - better chat for Web interface
redirection - allows redirecting to another server in case of switching host
shaders - customized shaders from community to allow disabling them in toxic panel
toxic - user panel and much more
trainingmode - allows players to respawn and train after being dead on maps without respawn
widgets - user interface resources with support for VIP panel
