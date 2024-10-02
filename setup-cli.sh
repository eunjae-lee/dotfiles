#!/bin/zsh
sudo cp ~/workspace/dotfiles/app-configs/cli/dev.eunjae.cli.plist /Library/LaunchDaemons
sudo launchctl load -w /Library/LaunchDaemons/dev.eunjae.cli.plist
sudo launchctl start -w /Library/LaunchDaemons/dev.eunjae.cli.plist

# sudo launchctl stop -w /Library/LaunchDaemons/dev.eunjae.cli.plist
# sudo launchctl unload -w /Library/LaunchDaemons/dev.eunjae.cli.plist
