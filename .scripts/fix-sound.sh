#!/bin/sh
sudo vim /usr/share/pulseaudio/alsa-mixer/paths/analog-output.conf.common

#change:
#[Element PCM]
#switch = mute
#volume = merge
#override-map.1 = all
#override-map.2 = all-left,all-right

#to:
#[Element Master]
#switch = mute
#volume = ignore


#[Element PCM]
#switch = mute
#volume = merge
#override-map.1 = all
#override-map.2 = all-left,all-right


#[Element LFE]
#switch = mute
#volume = ignore
