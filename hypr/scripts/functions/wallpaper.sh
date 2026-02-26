#!/usr/bin/env bash

SOCKET="/tmp/gslapper.sock"
CYCLE_PID_FILE="/tmp/gslapper-cycle.pid"
WALLPAPERS_DIR="$HOME/documents/wallpapers"
RESOLUTION='1080p'

usage() {
    echo "Usage: wallpaper.sh [--daemon [static|animated]] [next|prev|stop]"
}

stop() {
    kill_cycle

    if [[ -S "$SOCKET" ]]; then
        echo "stop" | nc -W1 -U "$SOCKET"
    fi
}


next() {
    current="$(echo "query" | nc -W1 -U "$SOCKET" | grep 'STATUS' | awk '{print $4}')"
    wallpapers=("$(dirname $current)"/*)
    for i in "${!wallpapers[@]}"; do
        if [[ "${wallpapers[$i]}" == "$current" ]]; then
            next_index=$(( (i + 1) % ${#wallpapers[@]} ))
            # If it is a video (*.mp4), restart daemon
            if [[ "${wallpapers[$next_index]}" == *.mp4 ]]; then
                daemon "$(dirname $current)" "$next_index"
                return 0
            fi
            echo "change ${wallpapers[$next_index]}" | nc -W1 -U "$SOCKET"
            break
        fi
    done
}
CYCLE_PID_FILE="/tmp/gslapper-cycle.pid"

kill_cycle() {
    [[ -f "$CYCLE_PID_FILE" ]] || return 0

    local pgid
    pgid="$(cat "$CYCLE_PID_FILE")"

    if [[ -n "$pgid" ]] && kill -0 "-$pgid" 2>/dev/null; then
        kill -TERM "-$pgid" 2>/dev/null
        sleep 0.2
        kill -KILL "-$pgid" 2>/dev/null || true
    fi

    rm -f "$CYCLE_PID_FILE"
}

start_cycle() {
    kill_cycle

    (
        # new process group
        set -m
        trap 'exit 0' INT TERM EXIT

        while true; do
            sleep 1500
            next
        done
    ) &

    # store PGID (not PID)
    echo "$(ps -o pgid= $!)" | tr -d ' ' > "$CYCLE_PID_FILE"
}


daemon() {
    real_dir="$1"
    idx=${2:-0}
    stop
    start_cycle
    gslapper -f \
        -n 25 \
        -r 30 \
        --transition-type fade \
        --transition-duration 0.5 \
        -I "$SOCKET" \
        -o "no-audio loop" \
        '*' \
        "$real_dir/$(ls "$real_dir" | head -n $((idx + 1)) | tail -n 1)" &
    exit 0
}

action() {
    case "$1" in
        next)
            next
            ;;
        stop)
            stop
            ;;
        *)
            usage
            exit 1
            ;;
    esac
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --daemon)
            shift
            if ! [[ "$1" =~ ^(static|animated)$ ]]; then
                usage
                exit 1
            fi
            daemon "$WALLPAPERS_DIR/$1/$RESOLUTION"
            ;;
        next|stop)
            action "$1"
            shift
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done
