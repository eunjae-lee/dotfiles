#!/bin/zsh

echo "Installing apps from App Store"
brew install mas
apps_app_store=(
  1487937127 # Craft
  1465439395 # Dark Noise
  904280696 # Things3
  869223134 # KakaoTalk
  639968404 # Parcel
  1453273600 # Data Jar
  1604176982 # One Thing
  1425368544 # Timery
  6450279539 # Second Clock
  1607635845 # Velja
  1586435171 # Actions
)
mas install ${apps_app_store[@]}

# install apps with brew cask
apps=(
  slack
  firefox
  google-chrome
  # spotify
  iterm2
  visual-studio-code
  # karabiner-elements
  discord
  iina
  insomnia
  fork
  docker
  google-chrome@canary
  raycast
  telegram
  # keycastr
  handbrake
  notion
  # postman
  zed
  input-source-pro # https://inputsource.pro/
  whatsapp
)
echo "installing apps with Cask..."
brew install --cask ${apps[@]}

# Configure Zed
rm -f ~/.config/zed/settings.json
rm -f ~/.config/zed/keymap.json
ln -s ~/workspace/dotfiles/app-configs/zed/settings.json ~/.config/zed/settings.json
ln -s ~/workspace/dotfiles/app-configs/zed/keymap.json ~/.config/zed/keymap.json

# Configure VSCode
rm -f ~/Library/Application\ Support/Code/User/keybindings.json
rm -f ~/Library/Application\ Support/Code/User/settings.json
ln -s ~/workspace/dotfiles/app-configs/vscode/keybindings.json ~/Library/Application\ Support/Code/User/keybindings.json
ln -s ~/workspace/dotfiles/app-configs/vscode/settings.json ~/Library/Application\ Support/Code/User/settings.json

# echo "Installing karabiner config"
# ln -s ~/workspace/dotfiles/app-configs/karabiner/karabiner.json ~/.config/karabiner/karabiner.json

# install one-thing CLI
npm install -g one-thing
