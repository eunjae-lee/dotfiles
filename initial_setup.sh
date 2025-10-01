#!/bin/bash

echo "Installing Homebrew..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew update

echo "Setting up SSH key for GitHub..."
ssh-keygen -t rsa
cat ~/.ssh/id_rsa.pub | pbcopy
open "https://github.com/settings/ssh/new"
read -p "Press Enter to continue..."

brew install git
mkdir -p ~/sandbox
mkdir ~/workspace
cd ~/workspace
git clone git@github.com:eunjae-lee/dotfiles.git

cd dotfiles
./dots/bin/dots apply --yes
