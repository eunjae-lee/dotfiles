#!/bin/zsh

echo "Setting up dotfiles..."
mkdir -p ~/workspace/
git clone git@github.com:eunjae-lee/dotfiles.git ~/workspace/dotfiles

ln -s ~/workspace/dotfiles/.gitconfig ~/.gitconfig
ln -s ~/workspace/dotfiles/.tool-versions ~/.tool-versions

ln -s ~/workspace/dotfiles/app-configs/raycast-scripts ~/workspace/raycast-scripts