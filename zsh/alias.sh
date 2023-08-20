#!/bin/bash

## Config files/folders
# Edit files
alias mhost="sudo -E -s $EDITOR /etc/hosts"
alias phpc="sudo -E -s $EDITOR /etc/php72/php.ini"
alias httpdc="sudo -E -s $EDITOR /etc/httpd/conf/httpd.conf"
alias bashrc="$EDITOR ~/.bashrc"
alias zshrc="$EDITOR ~/.zshrc"
alias qtilec="$EDITOR ~/.config/qtile/config.py"
# Enter to the config folder
alias dotfiles='cd /home/js/.config/dotfiles'
alias bridge='cd /home/js/bridge'



## Beautify commands
# ls
alias ls='exa --git --icons'
alias ll='exa --git --icons --long --octal-permissions'
alias lla='exa --git --icons --long --all --all --octal-permissions'
alias tree='exa --git --icons --tree'
# cat
alias cat='bat'



## Simplify commands
# systemctl
alias syst='sudo systemctl start'
alias sysr='sudo systemctl restart'
alias syso='sudo systemctl stop'
alias sysa='sudo systemctl status'
# pacman
alias get='sudo pacman -S'
alias rem='sudo pacman -R'
alias srch='pacman -Ss'
alias lstin="pacman -Qi | sed '/^Name/{ s/  *//; s/^.* //; H;N;d}; /^URL/,/^Build Date/d; /^Install Reason/,/^Description/d; /^  */d;x; s/^.*: ... //; s/Jan/01/;  s/Feb/02/;  s/Mar/03/;  s/Apr/04/;  s/May/05/;  s/Jun/06/;  s/Jul/07/;  s/Aug/08/; s/Sep/09/; s/Oct/10/;  s/Nov/11/;  s/Dec/12/; / [1-9]\{1\} /{ s/[[:digit:]]\{1\}/0&/3 }; s/\(^[[:digit:]][[:digit:]]\) \([[:digit:]][[:digit:]]\) \(.*\) \(....\)/\4-\1-\2 \3/' | sed ' /^[[:alnum:]].*$/ N; s/\n/ /; s/\(^[[:graph:]]*\) \(.*$\)/\2 \1/'"
# yay
alias yget='yay -S'
alias yrem='yay -R'
# snap
alias srem='sudo snap remove'
alias sget='sudo snap install'
# apt
alias aget='sudo apt install'
alias arem='sudo apt remove'
# svn
alias svnni="svn st | sed -e \"/^--- Changelist 'ignore'/,/^--- Changelist/d\" | grep '^[ADMR!]' | sed 's/^[ADMR!]//g'"
alias svndiff="svnni | xargs -I'file' svn diff \"file\" | bat -l patch"
# php
alias php='php72'
alias migrate='php bin/console doctrine:migrations:migrate'
alias mkmigration="php bin/console make:migration | grep \"new migration\" | awk -F'\"' '{print \$2}'"
# python
alias py='python3'
alias pysv="sudo python -m http.server 9000"
# get ips
alias gip='ip a | grep 192.168 | awk "{print \$2}"'
alias gtunip="$(ip a | grep -A3 tun0 | grep inet | awk '{print $2}' | cut -d '/' -f 1 | head -n 1)"
# others
alias msfconsole="msfconsole -x \"db_connect js@msf\""
alias htbi="sudo openvpn ~/hacking/hackthebox/htb-vpn.ovpn"
alias grep='grep --color=auto'
alias lc='light-control'
alias ocr="/home/js/.customscripts/ocr-selection"
alias sshn='ssh js@192.168.1.37'
alias rs='source /home/js/.zshrc'
alias kipin='~/.customscripts/kipin/init'
alias tgp='toggleprompt'



## Error logs
alias qtilee='cat ~/.local/share/qtile/qtile.log | tail -n 40 | bat -l log'
alias betalog='initial_path=$(pwd) && cd /tmp && wget ftp://logsbeta%2540dattacargo.com:LogsBeta.2021@dattacargo.com/prod.log && cat ./prod.log | tac | head | bat -l log && rm ./prod.log && cd $initial_path'



## Kill processes
alias kds='pkill -f discord; pkill -f Discord'
alias klol='pkill -f lutris'
