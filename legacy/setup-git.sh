#!/bin/zsh

echo "Setting up SSH key for GitHub..."
ssh-keygen -t rsa
cat ~/.ssh/id_rsa.pub | pbcopy
open "https://github.com/settings/ssh/new"

echo "Installing Git..."
brew install git gh lazygit
