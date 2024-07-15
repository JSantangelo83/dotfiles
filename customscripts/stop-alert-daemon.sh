#!/usr/bin/bash

touch /tmp/stopalarm;
pkill pw-play;
sleep 2
rm /tmp/stopalarm;
