#!/bin/bash

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

function search_db(){
  needle="$1"
  if [ -z "$needle" ]; then
    echo -e "\nUsage: $0 <db to find>\nEx: $0 transmodal"
    # exit 1
  fi
  found=0
  while read uri; do
    protocol="$(echo $uri | grep :// | sed -e's,^\(.*://\).*,\1,g')"
    url="$(echo ${uri/$protocol/})"
    user="$(echo $url | grep @ | cut -d@ -f1 | cut -d: -f1)"
    password="$(echo $url | grep @ | cut -d@ -f1 | cut -d: -f2)"
    hostport="$(echo $url | grep @ | cut -d@ -f2 | cut -d/ -f1)"
    host="$(echo $hostport | cut -d: -f1)"
    port="$(echo $hostport | cut -d: -f2)"    
    pass="$([[ -z "$password" ]] && echo -n 'root' || echo -n "$password")"
    echo "[!] Looking in $host..."
    if mariadb -u $user -p$pass -h $host -P $port -e 'show databases;' --skip-ssl 2>&1 | tail -n +3 | grep -v 'WARNING' | grep -wq "$needle"; then
      echo "Found: $host ($user:$pass)"
      found=1     
      break;
    fi
  done <<< "$(cat docker-compose.yml | grep -oE 'mysql://(.)+\s' | sort -u)"
  
  if [ $found -eq 1 ]; then
    echo -n "Do you want to connect to the database? [Y/n]: "
    read response
    response=${response:-Y}

    if [[ $response =~ ^[Yy]$ ]]; then
      echo "Connecting to the database..."
      mycli -u "$user" -p$pass -h "$host" -P "$port" "$needle"
    fi
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

function nocolor(){
 sed -r 's/\x1B\[[0-9;]*[JKmsu]//g'
}

function dumprow () {
	if [[ $# -eq 0 ]] then
		echo 'No params supplied'
	elif [[ $# -eq 1 ]] then
		mariadb-dump -u root -h 127.0.1 -P 3306 --skip-ssl --compact dattacargo33 -t "$1"
	elif [[ $# -eq 2 ]] then
		mariadb-dump -u root -h 127.0.1 -P 3306 --skip-ssl --compact dattacargo33 -t "$1" --where "$2"
	elif [[ $# -eq 3 ]] then
		mariadb-dump -u root -h 127.0.1 -P 3306 --skip-ssl --compact "$3" -t "$1" --where "$2"
	else
		echo 'Only 1 (table), 2 (where) or 3 (database) params accepted'
	fi
}

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

function svnci(){
	
	# Checks if the user is in production
	if [[ $(pwd) =~ "kipin-prod" ]]; then
		echo "You are in production, you can't commit here"
		return 1
	fi

	# Checks if something was piped to the function
	if [[ ! -p /dev/stdin || $# -lt 2 ]]; then
		echo 'Usage: <files> | svnci <task_number> <msg>\n\nExample:\nsvnni | svnci 1234 "Fixing bug"'
		return 1
	fi

	# Get the arguments
	tarea="$1"
	msj="$2"
	local files	

	# Read the piped files
	while IFS= read -r line; do
		line="${line#"${line%%[![:space:]]*}"}"   # Strip leading spaces
		line="${line%"${line##*[![:space:]]}"}"   # Strip trailing spaces
		files+=" '${line}'" # Add to the string
	done

	# Check if there are blacklisted words
	svnni | xargs -I'file' svn diff "file" | grep -nE 'dump|var_dump|console.log|pito|pene'

	commit='true';
	
	# If there are words that are not allowed, i ask if the user wants to continue
	if [[ $? -eq 0 ]] then
		commit=''
		echo '------------------------------'
		echo -ne "Blacklisted words found, do you want to commit anyway? (y/n): "; read res < /dev/tty

		if [[ $res =~ ^[Yy]$ ]] then
			commit='true'
		fi
	fi
	echo $files;
	
	# If the user wants to commit, i do it
	if [[ ! -z $commit ]] then
		svn ci -m "$msj
Tarea: $tarea" $files
	fi

	return 0;
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

