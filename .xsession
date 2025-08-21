#!/bin/sh

userresources=$HOME/.Xresources
usermodmap=$HOME/.Xmodmap
sysresources=/etc/X11/xinit/.Xresources
sysmodmap=/etc/X11/xinit/.Xmodmap

# merge in defaults and keymaps

if [ -f $sysresources ]; then
    xrdb -merge $sysresources
fi

if [ -f $sysmodmap ]; then
    xmodmap $sysmodmap
fi

if [ -f "$userresources" ]; then
    xrdb -merge "$userresources"
fi

if [ -f "$usermodmap" ]; then
    xmodmap "$usermodmap"
fi

# start some nice programs

if [ -d /etc/X11/xinit/xinitrc.d ] ; then
 for f in /etc/X11/xinit/xinitrc.d/?*.sh ; do
  [ -x "$f" ] && . "$f"
 done
 unset f
fi
xset s off && xset -dpms && xset s noblank &&
picom &
# xmodmap ~/.config/xremap &
easyeffects --gapplication-service &
/home/js/.customscripts/next-wallpaper &
sudo sh -c 'echo "abi.vsyscall32 = 0" >> /etc/sysctl.conf && sysctl -p' &
sudo mount -a &
sudo updatedb &
bash /home/js/.config/wacom/init.sh & 
/home/js/.customscripts/start-ufw &
