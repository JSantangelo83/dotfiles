#!/bin/bash

# Resources usages
function memusage() top -o %MEM -b -n1 | tail +8 | head -n ${1:-6} | awk '{print toupper( substr( $12, 1, 1 ) ) substr( $12, 2 )" "$10"%"}'
function cpusage() top -o %CPU -b -n1 | tail +8 | head -n ${1:-6} | awk '{print toupper( substr( $12, 1, 1 ) ) substr( $12, 2 )" "$9"%"}'

# Convertions between bases
function tohex() echo "obase=16;$1" | bc
function tobin() echo "obase=2;$1" | bc
function fromhex() echo "obase=10;ibase=16;$1" | bc
function frombin() echo "obase=10;ibase=2;$1" | bc

function dumprow () {
	if [[ $# -eq 0 ]] then
		echo 'No params supplied'
	elif [[ $# -eq 1 ]] then
		mysqldump --compact -u js dattacargo33 -t "$1"
	elif [[ $# -eq 2 ]] then
		mysqldump --compact -u js dattacargo33 -t "$1" --where "$2"
	else
		echo 'Only 1 or 2 params accepted'
	fi
}

function toggleprompt(){
	if [ "$PS1" \=\= "$FULL_PROMPT" ]; then
		export PS1=$MIN_PROMPT
	else
		export PS1=$FULL_PROMPT
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