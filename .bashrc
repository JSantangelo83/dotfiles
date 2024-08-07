#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# cat ~/.cache/wal/sequences
#system
alias ls='ls --color=auto'
alias bashrc='edtw ~/.bashrc'
alias zshrc='edtw ~/.zshrc'
alias py='python3 '
alias mkpy='~/.customscripts/touchpy'
alias mksh='~/.customscripts/touchsh'
alias gip='ip a | grep 192.168 | awk "{print \$2}"'
alias syst='sudo systemctl start'
alias sysr='sudo systemctl restart'
alias syso='sudo systemctl stop'
alias sysa='sudo systemctl status'
alias mhost='sudo micro /etc/hosts'
oak () { "$@" & disown & exit; }
alias sshn='ssh js@192.168.1.37'

#pacman
alias get='sudo pacman -S'
alias rem='sudo pacman -R'
alias lstin="pacman -Qi | sed '/^Name/{ s/  *//; s/^.* //; H;N;d}; /^URL/,/^Build Date/d; /^Install Reason/,/^Description/d; /^  */d;x; s/^.*: ... //; s/Jan/01/;  s/Feb/02/;  s/Mar/03/;  s/Apr/04/;  s/May/05/;  s/Jun/06/;  s/Jul/07/;  s/Aug/08/; s/Sep/09/; s/Oct/10/;  s/Nov/11/;  s/Dec/12/; / [1-9]\{1\} /{ s/[[:digit:]]\{1\}/0&/3 }; s/\(^[[:digit:]][[:digit:]]\) \([[:digit:]][[:digit:]]\) \(.*\) \(....\)/\4-\1-\2 \3/' | sed ' /^[[:alnum:]].*$/ N; s/\n/ /; s/\(^[[:graph:]]*\) \(.*$\)/\2 \1/'"
# alias lstin='grep -i " installed" /var/log/pacman.log | awk "{print \$4}"'
#apt
alias aget='sudo apt install'
alias arem='sudo apt remove'
#qtile
alias qtilec='edtw ~/.config/qtile/config.py'
alias qtilee='bat ~/.local/share/qtile/qtile.log'
alias fqkey='bat ~/.config/qtile/keys | grep'
#yay
alias yget='yay -S'
alias yrem='yay -R'
#snap
alias srem='sudo snap remove'
alias sget='sudo snap install'
#svn
alias svnni="svn st | sed -e \"/^--- Changelist 'ignore'/,/^--- Changelist/d\" | grep '^[ADMR!]' | awk '{print \$2}'"
alias svndiff="svnni | xargs svn diff > a.patch && bat a.patch && rm a.patch"
#kipin
alias kipin='~/.customscripts/kipin/init'
alias betalog='initial_path=$(pwd) && cd /tmp && wget ftp://logsbeta%2540dattacargo.com:LogsBeta.2021@dattacargo.com/prod.log && cat ./prod.log | tail -100 | micro && rm ./prod.log && cd $initial_path'

function dumprow () { mysqldump --compact -u js dattacargo33 -t "$1" --where "$2";}
#msf
alias msfconsole="msfconsole -x \"db_connect js@msf\""
#nvm
alias nvmi="source /usr/share/nvm/init-nvm.sh;nvm use 12.14"
#htb
alias htbinit="sudo openvpn ~/hacking/hackthebox/htb-vpn.ovpn"
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
alias ocr="$HOME/.customscripts/ocr-selection"

#prompts
# <---- caracter problematico
PS1=" \[\e[1;3;35m\]\w \[\e[31m\] \[\e[0\]m"
PS2=" \[\e[1;31m\] \[\e[0\]m"

#Variables
export LC_ALL="C"
export EDITOR=vim
export BROWSER=opera
export nb='192.168.1.37'
export TESSDATA_PREFIX='/usr/share/tessdata/'

OPERAPLUGINWRAPPER_PRIORITY=0
OPERA_KEEP_BLOCKED_PLUGIN=1
GDK_NATIVE_WINDOWS=1

PATH="/usr/NX/bin/:$HOME/.customscripts:/opt/lampp:$HOME/perl5/bin${PATH:+:${PATH}}"; export PATH;
PERL5LIB="$HOME/perl5/lib/perl5${PERL5LIB:+:${PERL5LIB}}"; export PERL5LIB;
PERL_LOCAL_LIB_ROOT="$HOME/perl5${PERL_LOCAL_LIB_ROOT:+:${PERL_LOCAL_LIB_ROOT}}"; export PERL_LOCAL_LIB_ROOT;
PERL_MB_OPT="--install_base \"$HOME/perl5\""; export PERL_MB_OPT;
PERL_MM_OPT="INSTALL_BASE=$HOME/perl5"; export PERL_MM_OPT;
shopt -s checkwinsize

banner

[ -f ~/.fzf.bash ] && source ~/.fzf.bash

export FZF_DEFAULT_OPS='-x -i'
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .Android --exclude snap --exclude .git --exclude .cache --exclude cache --exclude .vscode-oss --exclude .svn --exclude node-modules --exclude composer --exclude build'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
