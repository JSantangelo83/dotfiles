#!/usr/bin/env bash

# Hide Dock completely
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 1000
defaults write com.apple.dock autohide-time-modifier -float 0
defaults write com.apple.dock tilesize -int 1
defaults write com.apple.dock orientation -string left

# Remove visual junk
defaults write com.apple.dock show-process-indicators -bool false
defaults write com.apple.dock show-recents -bool false

# Restart Dock
killall Dock
