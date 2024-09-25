#!/usr/bin/bash

wf-recorder_check() {
	if pgrep -x "wf-recorder" > /dev/null; then
			pkill -INT -x wf-recorder
			notify-send "Stopping all instances of wf-recorder" "$(cat /tmp/recording.txt)"
			wl-copy < "$(cat /tmp/recording.txt)"
			exit 0
	fi
}
VID="${HOME}/documents/clips/$(date +%Y-%m-%d_%H-%m-%s).mp4"

wf-recorder_check
echo "$VID" > /tmp/recording.txt
wf-recorder -a -g "$(slurp)" -f "$VID"
