#!/bin/zsh

echo "Setting up dotfiles..."
mkdir -p ~/workspace/
git clone git@github.com:eunjae-lee/dotfiles.git ~/workspace/dotfiles

ln -s ~/workspace/dotfiles/.gitconfig ~/.gitconfig
ln -s ~/workspace/dotfiles/.tool-versions ~/.tool-versions

ln -s ~/workspace/dotfiles/app-configs/raycast-scripts ~/workspace/raycast-scripts

rm ~/Library/Application\ Support/lazygit/config.yml
ln -s ~/workspace/dotfiles/app-configs/lazygit/config.yml ~/Library/Application\ Support/lazygit/config.yml

git clone git@github.com:eunjae-lee/morning-routine.git ~/workspace/morning-routine
git clone git@github.com:eunjae-lee/eunjae-dev-nuxt.git ~/workspace/eunjae-dev-nuxt
git clone git@github.com:eunjae-lee/eunjae-cli.git ~/workspace/eunjae-cli
