#
# ~/.zshrc
#

# Source my custom scripts
export EDITOR=nvim

# source /usr/share/zsh/plugins/fzf-zsh-plugin/fzf-zsh-plugin.plugin.zsh;
source ~/.fzf.zsh
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh;
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh;
source ~/.config/zsh/perm_variables.sh;
source ~/.config/zsh/alias.sh;
source ~/.config/zsh/functions.sh;
source ~/.config/zsh/hacking.sh;

# If not running interactively, don't do anything
[[ $- != *i* ]] && return
export LC_ALL="C"
export BROWSER=firefox
export TESSDATA_PREFIX='/usr/share/tessdata/'
export dotfiles='/home/js/.config/dotfiles'
# export nb="$(cat /home/js/bridge/data/nb/public-ip)"
# export lnb="$(cat /home/js/bridge/data/nb/private-ip)"
export vnb="10.243.249.178"
# export pc="$(cat /home/js/bridge/data/pc/public-ip)"
# export lpc="$(cat /home/js/bridge/data/pc/private-ip)"
export vpc="10.243.246.143"
export light='192.168.1.50'
PATH="/usr/NX/bin/:${dotfiles}/customscripts/kipin/utilities:${dotfiles}/customscripts/kipin:${dotfiles}/customscripts:/opt/lampp:/home/js/perl5/bin${PATH:+:${PATH}}"; export PATH;
export HISTCONTROL=ignoredups:erasedups  # no duplicate entries
export HISTSIZE=100000                   # big big history
export HISTFILESIZE=100000               # big big history
export SAVEHIST=100000 					 # big big history
export FZF_DEFAULT_OPS='-x -i'
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .Android --exclude snap --exclude .git --exclude .cache --exclude cache --exclude .vscode-oss --exclude .svn --exclude node-modules --exclude composer --exclude build'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
PERL5LIB="/home/js/perl5/lib/perl5${PERL5LIB:+:${PERL5LIB}}"; export PERL5LIB;
PERL_LOCAL_LIB_ROOT="/home/js/perl5${PERL_LOCAL_LIB_ROOT:+:${PERL_LOCAL_LIB_ROOT}}"; export PERL_LOCAL_LIB_ROOT;
PERL_MB_OPT="--install_base \"/home/js/perl5\""; export PERL_MB_OPT;
PERL_MM_OPT="INSTALL_BASE=/home/js/perl5"; export PERL_MM_OPT;
OPERAPLUGINWRAPPER_PRIORITY=0
OPERA_KEEP_BLOCKED_PLUGIN=1
GDK_NATIVE_WINDOWS=1
MAILCHECK=0

## Prompt
FULL_PROMPT=$' %{\e[1;3;35m%}%~ %{\e[31m%} %{\e[0%}m'
MIN_PROMPT=$' %{\e[1;3;35m%}%1d %{\e[31m%} %{\e[0%}m'
PS1=$FULL_PROMPT
PS2=$' %{\e[31m%} %{\e[0%}m'
PROMPT_FULLED=true;

if [ $SHELL != '/bin/zsh' ]; then
  shopt -s checkwinsize
  #History
  shopt -s histappend                      
fi

# append to history, don't overwrite it
# Appends every command to the history file once it is executed
setopt inc_append_history
# Reloads the history whenever you use it
setopt share_history
setopt HIST_IGNORE_SPACE
# Save and reload the history after each command finishes
HISTFILE=~/.zsh_history


# Zsh Keybinds
bindkey  "^[[H"   beginning-of-line
bindkey  "^[[F"   end-of-line
bindkey  "^[[3~"  delete-char
bindkey "^d" kill-path-word
bindkey "^p" toggleprompt
bindkey "^[[1;5D" dir_back
bindkey "^[[1;5C" dir_fwd
#
zle -N dir_back
zle -N dir_fwd
zle -N toggleprompt
# Zsh Plugins and Functions
zle -N kill-path-word
# Pushd's to the starting_path if there is any
cd $starting_path 
# if [ $(ps -o ppid= | wc -l) -eq 4 ]; then
#   if ! [ -z $starting_path ]; then
#      cd $starting_path
#   fi
# fi
eval $(ssh-agent -s) &>/dev/null                                                                         [ 4ms ]
ssh-add ~/.ssh/id_rsa &>/dev/null                                                                        [ 4ms ]
ssh-add ~/.ssh/ip_provider   &>/dev/null
# Programs to execute at the start of zsh
banner
