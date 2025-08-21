#!/bin/bash
pushd /tmp || exit 1

# Creating files
logdir='/var/log/lootboxes'

sudo mkdir -p "$logdir" &>/dev/null; 
sudo chmod 777 "$logdir" &>/dev/null;
touch "$logdir/used.txt"
touch "$logdir/found.txt"
if ! [ -d "$logdir" ] || ! [ -w "$logdir" ] || ! [ -r "$logdir" ]; then
  echo '[x] Error, no place for logs';
  exit 1;
fi

# Generate wordlist
length=10000
if [ -n "$1" ]; then
  length="$1"
fi

wl=$(cat /dev/urandom | tr -dc '[:alpha:]' | fold -w 8 | head -n $length | grep -vxf "$logdir/used.txt")

echo -e "$wl" >> "$logdir/used.txt"

echo -e "$wl" | ffuf -c -t 200 -w /dev/stdin -u 'https://bunkr.si/a/FUZZ' -fr 'The album or file you have requested no longer exists, or never existed.' -sf -of csv -o "$logdir/output.last.txt"

# echo -e "$wl" | ffuf -c -t 200 -w /dev/stdin -u 'https://bunkr.si/a/FUZZ' -fr 'Gofile is a free, secure file sharing' -sf -of csv -o "$logdir/output.last.txt"
if [ -f "$logdir/output.last.txt" ]; then
  urls="$(tail -n +2 $logdir/output.last.txt | awk -F',' '{print $2}')"
  echo -e "$urls" >> "$logdir/found.txt"
fi
