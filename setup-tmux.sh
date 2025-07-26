#!/bin/sh

brew install tmux
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
ln -s ~/workspace/dotfiles/app-configs/tmux.conf ~/.tmux.conf
