#!/bin/zsh

# REPLACE THIS WITH https://mise.jdx.dev/lang/node.html#nvmrc-and-node-version-support

echo "Setting up node.js..."
# asdf
# https://gist.github.com/Grawl/461c7c1acfcf7e2ecbf99ce9fed40c31
brew install asdf
# echo ". /usr/local/opt/asdf/libexec/asdf.sh" >> ~/.zshrc
asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git
brew install gnupg
asdf install nodejs latest
asdf global nodejs latest

asdf plugin add alias https://github.com/andrewthauer/asdf-alias.git
asdf alias nodejs 20 20.10.0
asdf alias nodejs 18 18.20.4

asdf plugin-add pnpm
asdf install pnpm latest
asdf global pnpm latest

asdf plugin add ni https://github.com/CanRau/asdf-ni.git
asdf install ni latest
asdf global ni latest
