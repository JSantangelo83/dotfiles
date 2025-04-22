function usage(){
    echo "$0 <start|stop>"
}

function start(){
    pkill waybar;
    ags --quit;
    # ags &> /tmp/pijota
    ags & (sleep 1 && waybar -c /home/js/.config/waybar/tray_config -s /home/js/.config/waybar/style.css);
}

function stop(){
    pkill waybar
    ags --quit
}

if [ $# -ne 1 ]; then
    usage
    exit 1
fi

case $1 in
    start)
        start
        ;;
    stop)
        stop
        ;;
    *)
        usage
        exit 1
        ;;
esac
