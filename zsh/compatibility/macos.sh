#!/bin/zsh

# defaults write com.apple.dock expose-group-apps -bool true && killall Dock
# defaults write com.apple.spaces spans-displays -bool true && killall SystemUIServer
# defaults write com.apple.Terminal NSQuitAlwaysKeepsWindows -bool false
# defaults write com.apple.Terminal TTYKeepWindowsAcrossLaunches -bool false
# defaults write com.apple.loginwindow TALLogoutSavesState -bool false
# defaults write com.apple.loginwindow LoginwindowLaunchesRelaunchApps -bool false
# defaults write -g ApplePersistenceIgnoreState -bool true


alias sed='gsed'
alias get='brew install'

export DOCKER_HOST="unix:///Users/js/.colima/default/docker.sock"
export TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE=/var/run/docker.sock

export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# Scape sequences differ in mac
bindkey "^[[1;3D" dir_back
bindkey "^[[1;3C" dir_fwd
bindkey  "^[[1;9D"   beginning-of-line
bindkey  "^[[1;9C"   end-of-line
