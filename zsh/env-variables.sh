## idk what this is for
export LC_ALL="C"
export TESSDATA_PREFIX='/usr/share/tessdata/'

# System
export GDK_NATIVE_WINDOWS=1
export MAILCHECK=0
export EDITOR='nvim'
export dotfiles="$HOME/.config/dotfiles"
export PATH="/usr/NX/bin/:${dotfiles}/customscripts/kipin/utilities:${dotfiles}/customscripts/kipin:${dotfiles}/customscripts:/opt/lampp:$HOME/perl5/bin${PATH:+:${PATH}}"; 
export BROWSER=firefox

# Opera
export OPERAPLUGINWRAPPER_PRIORITY=0
export OPERA_KEEP_BLOCKED_PLUGIN=1

# History
export HISTFILE=~/.zsh_history
export HISTCONTROL=ignoredups:erasedups  # no duplicate entries
export HISTSIZE=100000                   # big big history
export HISTFILESIZE=100000               # big big history
export SAVEHIST=100000 					 # big big history

# FZF 
export FZF_DEFAULT_OPS='-x -i'
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .Android --exclude snap --exclude .git --exclude .cache --exclude cache --exclude .vscode-oss --exclude .svn --exclude node-modules --exclude composer --exclude build'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# HackTheBox
export HTB_TOKEN='eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJhdWQiOiI1IiwianRpIjoiZjA3OWVlY2EyNDU3ODQyOWE0NjIzNWFiNmRkMWQ1NGZhNmQyMGUyMGQ3MDk2NzQ1YmE3YTgzMDZiOTQwYzdiOGFkZGJjNzhjYTM3MjAwZDAiLCJpYXQiOjE3MjEwODg1OTUuMzEwNTI5LCJuYmYiOjE3MjEwODg1OTUuMzEwNTMxLCJleHAiOjE3NTI2MjQ1OTUuMzAyODI5LCJzdWIiOiI4ODc2NzciLCJzY29wZXMiOltdfQ.yrDgquEBsdIi3TSDpKJFQAh2mmsMbi1hkRcAEacqOA35ex68pRyDBZoWBbh8ouB8FasjFlNaJaXH_OBYMOh-51Ft-l994r3ERw1w8a5UbjAI6RPkcOTBe_DqgjUVJY1v_6VgL8buIZjo3YwbQd_7zyX5JkZFuTi-33rad1gJl3yQJEt7eq5MForKb-LZI43nVm5n4pMRVuv_jd8m8o6x8pDhAF8VShNBxjktP8787rassyVFN5minZOdug8UzNiy8AfSzK7XsuOk4sUa6Xw40CB0xsiTTlR5Te6m8Wu8XwKjI8rV10OtGOl0kVlC91diHk3zgj2NkWTiiwDAhmwPDS-mLkWz3SRormJRozdYyJAQgnSjmnD8AapRe3a3_shcz9AMCiUihEGYZqTyMH_p3UgVeXnIpeceZ4f8Z9vsZ9xBl_kRwOhXWBx1hFpaRS-3LCDLiRqfKOlPxhHsL1bnzZNrY9FuAEjfShcH3sjS3S45czkGfAnDDd3Nnb3qoJjMzx_dAN0D0flmD36X4IaHehOnC3a2AE_nNjqacPCBQzZ_arF_lIDEPFPHeApaxNxUhz1J1lKB2dZjZGSfG3_EzNPPUhNEKjoHP9JNQH-L-QKAYM4epSUT6oKn4l6tBb499Z2JBw2ZP9XfSnEC01NQI9FcX01krAU3wL8XsE28drA'

# Perl
export PERL5LIB="$HOME/perl5/lib/perl5${PERL5LIB:+:${PERL5LIB}}"
export PERL_LOCAL_LIB_ROOT="$HOME/perl5${PERL_LOCAL_LIB_ROOT:+:${PERL_LOCAL_LIB_ROOT}}"
export PERL_MB_OPT="--install_base \"$HOME/perl5\""
export PERL_MM_OPT="INSTALL_BASE=$HOME/perl5"

## Prompts
FULL_PROMPT=$' %{\e[1;3;35m%}%~ %{\e[31m%} %{\e[0%}m'
MIN_PROMPT=$' %{\e[1;3;35m%}%1d %{\e[31m%} %{\e[0%}m'
PS1=$FULL_PROMPT
PS2=$' %{\e[31m%} %{\e[0%}m'
PROMPT_FULLED=true;
