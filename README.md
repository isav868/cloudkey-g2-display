# README #

## Important ##

This is a fork of an original repo: https://bitbucket.org/dskillin/cloudkey-g2-display.git

Requires the installation of ImageMagick and sysstat

`apt-get install imagemagick sysstat`

### What is this repository for? ###

One example script to place custom information on the screen of a Gen 2 CloudKey.
Primarily intended for systems converted to be headless linux systems.

Jason Anderson has a solid write up.
https://fullduplextech.com/turn-unifi-cloud-key-gen-2-into-a-headless-linux-server/

### How do I get set up? ###

This is intended to be an example of placing TEXT on the screen.  In this case I am opting for
```
IP Address/Hostname
Time
CPU and Memory %
```
Change the font variable to suit your taste.

Best if used in a cron job, once every one to five minutes per your taste.

crontab:
```
@reboot              flock -n /run/lock/fbshow.lck fbshow.sh
*   *  *   *   *     flock -n /run/lock/fbshow.lck fbshow.sh
```

