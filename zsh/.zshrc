#If not running interactively, don't do anything
[[ $- != *i* ]] && return
# Source my custom scripts
source ~/.config/zsh/env-variables.sh;
source /usr/share/zsh/plugins/fzf-zsh-plugin/fzf-zsh-plugin.plugin.zsh;
source ~/.fzf.zsh
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh;
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh;
source ~/.config/zsh/perm_variables.sh;
source ~/.config/zsh/variables.sh;
source ~/.config/zsh/alias.sh;
source ~/.config/zsh/functions.sh;
source ~/.config/zsh/hacking.sh;

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

# Zsh Keybinds
bindkey  "^[[H"   beginning-of-line
bindkey  "^[[F"   end-of-line
bindkey  "^[[3~"  delete-char
bindkey "^d" kill-path-word
bindkey "^p" toggleprompt
bindkey "^x" update-starting-path
bindkey "^[[1;5D" dir_back
bindkey "^[[1;5C" dir_fwd
#
zle -N dir_back
zle -N dir_fwd
zle -N toggleprompt
zle -N update-starting-path
# Zsh Plugins and Functions
zle -N kill-path-word
# Pushd's to the starting_path if there is any
cd $starting_path
# sudo systemctl disable sshd
# sudo systemctl stop sshd

# TODO: matar esto de aca, banana solutionno va
export LC_ALL='C.UTF-8'

eval $(ssh-agent -s) &>/dev/null                                                                        
ssh-add ~/.ssh/id_rsa &>/dev/null                                                                        
ssh-add ~/.ssh/ip_provider   &>/dev/null

# Programs to execute at the start of zsh
banner
