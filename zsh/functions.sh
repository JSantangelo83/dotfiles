#!/bin/bash
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-${(%):-%N}}")" && pwd)"

info()  { echo -e "\e[32m[+] $1\e[0m"; }
warn()  { echo -e "\e[33m[!] $1\e[0m"; }
error() {
    echo -e "\e[31m[-] $1, exiting...\e[0m" >&2
    kill -s TERM "$$";
}

# Modify file with editor and sudo -sE (if specified)
function mdfy(){
  if [ -z $1 ]; then
    echo '[x] You must specify a file to edit' >&2
    return
  fi
  dir=$(dirname $1)
  file=$(basename $1)
  pushd $dir; 
  [[ -w "$file" ]] && $EDITOR $file || sudo -sE $EDITOR $file;
  popd; 
}

# Resources usages
function memusage() top -o %MEM -b -n1 | tail +8 | head -n ${1:-6} | awk '{print toupper( substr( $12, 1, 1 ) ) substr( $12, 2 )" "$10"%"}'
function cpusage() top -o %CPU -b -n1 | tail +8 | head -n ${1:-6} | awk '{print toupper( substr( $12, 1, 1 ) ) substr( $12, 2 )" "$9"%"}'

show_dicts() {
	sed -n '/# Dicts/,/# \/Dicts/p' $dotfiles/zsh/hacking.sh | grep -vE "# Dicts|# /Dicts" | sed 's/export //g' | tr '=' ' ' | awk '{print "\033[1;32m" $1 "\033[0m" " - " "\033[1;34m" $2 "\033[0m"}'
}


function svndiff {
  if [ -z $1 ]; then
    svnni | xargs svn diff --force | bat -l patch
  else
    rev="$1"
    svn diff -r"$((rev-1)):$rev" | bat -l patch
  fi
}

function getchar() {
  if [ -z "$1" ]; then
    echo '[x] You must specifiy a number of chars to copy to clipboard, exiting...'
    exit 1;
  fi
  
  python3 -c "print('A' * $1)" | clp
}

# Convertions between bases
function tohex() echo "obase=16;$1" | bc
function tobin() echo "obase=2;$1" | bc
function fromhex() echo "obase=10;ibase=16;$1" | bc
function frombin() echo "obase=10;ibase=2;$1" | bc

function dir_back() {
  if [[ $PWD != "/" ]]; then
      pushd ../ &>/dev/null || return 1
      zle reset-prompt;
  fi
}

function dir_fwd() {
  popd &>/dev/null || return 1
  zle reset-prompt;
}

function pysv(){
  addr="$(gtunip):9000"
  # The first param sets if thhe addr should be copied to thhe clipboard
  [ "$1" ] && echo -n "$addr" | xclip -sel c -r
  echo -e "[+] Listening on: $addr\n"
  python -m http.server 9000 1>/dev/null
  
}

function nocolor {
  sed -r 's/\x1B\[[0-9;]*[JKmsu]//g'
}

function _get_ipv4_by_iface {
  ip -4 -o addr show dev "$1" scope global up 2>/dev/null | awk '{split($4, cidr, "/"); print cidr[1]; exit}'
}

function _get_first_available_ipv4 {
  for iface in "$@"; do
    ip_addr="$(_get_ipv4_by_iface "$iface")"
    if [ -n "$ip_addr" ]; then
      echo "$ip_addr"
      return 0
    fi
  done
  return 1
}

function gprivip {
  default_iface="$(ip -4 route show default 2>/dev/null | awk '{print $5; exit}')"
  if [ -n "$default_iface" ]; then
    default_ip="$(_get_ipv4_by_iface "$default_iface")"
    if [ -n "$default_ip" ]; then
      echo "$default_ip"
      return 0
    fi
  fi
  _get_first_available_ipv4 enp5s0 wlan0 eth0 wlp2s0
}

function gtunip { _get_ipv4_by_iface tun0; }
function ghamip { _get_ipv4_by_iface ham0; }

function update-starting-path() {
  upvar starting_path "$(pwd)"
}

function column() {
  if [ -z "$1" ]; then
    echo -n "Usage: $0 <column number> [separator]\nEx: $0 1 ';'"
    exit 1;
  fi

  if [ -n "$2" ]; then
    awk -F"$2" "{print \$$1}" /dev/stdin
  else
    awk "{print \$$1}" /dev/stdin
  fi
}

# Prompt things
function toggleprompt(){
	if $PROMPT_FULLED; then
		PS1=$MIN_PROMPT
    PROMPT_FULLED=false;
	else
		PS1=$FULL_PROMPT
    PROMPT_FULLED=true;
	fi
  zle reset-prompt;
}

format_milliseconds() {
    local input_ms=$1

    if (( input_ms < 1000 )); then
        echo "${input_ms}ms"
    elif (( input_ms < 60000 )); then
        local seconds=$((input_ms / 1000))
        local milliseconds=$((input_ms % 1000))
        echo "${seconds}s ${milliseconds}ms"
    elif (( input_ms < 3600000 )); then
        local minutes=$((input_ms / 60000))
        local seconds=$(( (input_ms % 60000) / 1000 ))
        echo "${minutes}min ${seconds}s"
    else
        local hours=$((input_ms / 3600000))
        local minutes=$(( (input_ms % 3600000) / 60000 ))
        local seconds=$(( (input_ms % 60000) / 1000 ))
        echo "${hours}h ${minutes}min ${seconds}s"
    fi
}

preexec() {
    ts=$(date +%s%N) }

precmd() {
   exit_code=$?;
   if [ -z $ts ]; then return; fi;
     
   local tt=$((($(date +%s%N) - $ts)/1000000));

   if [ $exit_code -eq 0 ] ; then
     RPROMPT="%F{green}% [ $(format_milliseconds $tt) ]%f"
   else
     RPROMPT="%F{red}% [ $(format_milliseconds $tt) ]%f"
   fi

 }

function viewcolors () {
    colors=$(sed 's/#/\n/g' | grep -xv '')
    for i in {1..2}
    do
        echo "$colors" | while read line
        do
            echo -ne "\e[48;2;$((0x${line:0:2}));$((0x${line:2:2}));$((0x${line:4:2}))m       \e[0m"
        done
        echo -ne "\n"
    done
}

function kill-path-word(){
  local words word spaces
   zle set-mark-command                 # save current cursor position ("mark")
   while [[ $LBUFFER[-1] == "/" ]] {
     (( CURSOR -= 1 ))                  # consume all trailing slashes
  }
  words=("${(s:/:)LBUFFER/\~/_}")       # split command line at "/" after "~" is replaced by "_" to prevent FILENAME EXPANSION messing things up
  word=$words[-1]                       # this is the portion from cursor back to previous "/"
  (( CURSOR -= $#word ))                # then, jump to the previous "/"
  zle exchange-point-and-mark           # swap "mark" and "cursor"
  zle kill-region                       # delete marked region
}
