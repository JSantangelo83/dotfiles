#!/bin/sh
# The kernel console (and so tuigreet) is clamped to the smallest lit output,
# so with the side monitors on it only fills a 1024x768 box on DP-1.
# That size is fixed when fbdev is created at boot, so the side monitors are
# kept off from the start with video=DP-2:d video=DP-3:d (grub 40_custom);
# this hands them back on login and drops them again on logout.
#
#   console-monitors.sh off|on    - manual
#   via pam_exec (PAM_TYPE set)   - on at open_session, off at close_session

SIDE="card1-DP-2 card1-DP-3"

set_side() {
    for c in $SIDE; do
        [ -w "/sys/class/drm/$c/status" ] && echo "$1" > "/sys/class/drm/$c/status"
    done
}

# Block until the side outputs probe as connected (max ~3s), so the session
# (Hyprland) only starts once they're already there instead of hotplugging in.
wait_side() {
    i=0
    while [ $i -lt 30 ]; do
        ok=1
        for c in $SIDE; do
            [ "$(cat "/sys/class/drm/$c/status" 2>/dev/null)" = connected ] || ok=0
        done
        [ $ok = 1 ] && return 0
        sleep 0.1; i=$((i + 1))
    done
}

if [ -n "$PAM_TYPE" ]; then
    [ "$PAM_USER" = greeter ] && exit 0
    case "$PAM_TYPE" in
        open_session)  set_side detect; wait_side ;;
        close_session) set_side off ;;
    esac
    exit 0
fi

case "$1" in
    off) set_side off ;;
    on)  set_side detect; wait_side ;;
    *)   echo "usage: $0 off|on" >&2; exit 1 ;;
esac
