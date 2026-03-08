#If not running interactively, don't do anything
[[ $- != *i* ]] && return
# Source my custom scripts
source ~/.config/zsh/env-variables.sh;
source ~/.config/zsh/perm_variables.sh;
source ~/.config/zsh/variables.sh;
source ~/.config/zsh/alias.sh;
source ~/.config/zsh/functions.sh;
source ~/.config/zsh/hacking.sh;
if [ "$(uname -s)" = "Darwin" ]; then
  source ~/.config/zsh/compatibility/macos.sh;
fi

# fzf (fuzzy finder)
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# fnm (node version manager)
[ -f $(which fnm) ] && eval "$(fnm env --use-on-cd)"

# autosuggestions
if command -v brew >/dev/null 2>&1; then
  source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
elif [ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
  source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

# syntax highlighting (must be last)
if command -v brew >/dev/null 2>&1; then
  source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
elif [ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
  source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

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

# TODO: matar esto de aca, banana solution no va
export LC_ALL='C.UTF-8'

eval $(ssh-agent -s) &>/dev/null                                                                        
ssh-add ~/.ssh/id_rsa &>/dev/null                                                                        
ssh-add ~/.ssh/ip_provider   &>/dev/null

# Programs to execute at the start of zsh
banner
