#!/bin/zsh

echo "Setting up zsh..."

# https://unix.stackexchange.com/questions/557486/allowing-comments-in-interactive-zsh-commands
setopt interactive_comments

sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

git clone https://github.com/spaceship-prompt/spaceship-prompt.git "$ZSH_CUSTOM/themes/spaceship-prompt" --depth=1
ln -s "$ZSH_CUSTOM/themes/spaceship-prompt/spaceship.zsh-theme" "$ZSH_CUSTOM/themes/spaceship.zsh-theme"

git clone https://github.com/agkozak/zsh-z $ZSH_CUSTOM/plugins/zsh-z

rm .zshrc
ln -s ~/workspace/dotfiles/.zshrc .zshrc
