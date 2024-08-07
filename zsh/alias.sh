#!/bin/bash

## Config files/folders
# Edit files
alias mhost="mdfy /etc/hosts 1"
alias phpc="mdfy /etc/php72/php.ini 1"
alias httpdc="mdfy /etc/httpd/conf/httpd.conf 1"
alias bashrc="mdfy ~/.bashrc"
alias zshrc="mdfy ~/.zshrc"
alias qtilec="mdfy ~/.config/qtile/config.py"
alias sshdc="mdfy /etc/ssh/sshd_config 1"

# Enter to the config folder
alias dotfiles="cd $HOME/.config/dotfiles"
alias bridge="cd $HOME/bridge"
alias pkill='pkill -ife'

## Beautify commands
# ls
alias ls='exa --git --icons'
alias ll='exa --git --icons --long --octal-permissions'
alias lla='exa --git --icons --long --all --all --octal-permissions'
alias tree='exa --git --icons --tree'

# better commands
alias cat='bat'
alias grep='grep --color=auto'


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
alias svnni="svn st | sed -e \"/^--- Changelist 'ignore'/,/^--- Changelist/d\" | grep '^[ADMR!]' | sed 's/^[ADMR!]//g' | xargs -I{} echo '\"{}\"' "
alias svndiff="svnni | xargs -I'file' svn diff \"file\" | bat -l patch"

# php
alias php='php72'
alias migrate='dc exec backend-service php bin/console doctrine:migrations:migrate'
alias mkmigration="dc exec backend-service php bin/console make:migration | grep \"new migration\" | awk -F'\"' '{print \$2}'"

# python
alias py='python3'

# get ips
alias gprivip="ip a | grep -A2 -E '(enp5s0|wlan0): <' |tail -n1 | awk '{print \$2}' | sed 's/\/.*//g'"
alias gtunip="ip a | grep -A2 'tun0: <' |tail -n1 | awk '{print \$2}' | sed 's/\/.*//g'"
alias ghamip="ip a | grep -A2 'ham0: <' |tail -n1 | awk '{print \$2}' | sed 's/\/.*//g'"
alias gpubip="dig @resolver4.opendns.com myip.opendns.com +short"
alias gtrabuip="hamachi list | head -n2 | tail -n1 | column 4"
# docker
alias dc="sudo docker compose"

## Others
alias htbi="sudo openvpn ~/hacking/hackthebox/htb-vpn.ovpn"
alias lc='light-control'
alias ocr="$HOME/.customscripts/ocr-selection"
alias sshn='ssh js@192.168.1.37'
alias rs="source $HOME/.zshrc"
alias kipin='~/.customscripts/kipin/init'
alias tgp='toggleprompt'
alias clp='xclip -sel c -r'
alias ddp='dotdotpwn'
alias cd='dirs -c; cd'
alias nvmi='source /usr/share/nvm/init-nvm.sh'

## Error logs
alias qtilee='cat ~/.local/share/qtile/qtile.log | tail -n 40 | bat -l log'
alias betalog='initial_path=$(pwd) && cd /tmp && wget ftp://logsbeta%2540dattacargo.com:LogsBeta.2021@dattacargo.com/prod.log && cat ./prod.log | tac | head | bat -l log && rm ./prod.log && cd $initial_path'



## Kill processes
alias kds='pkill -f discord; pkill -f Discord'
alias klol='pkill -f lutris'

