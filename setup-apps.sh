#!/bin/zsh

echo "Installing apps from App Store"
brew install mas
apps_app_store=(
  1333542190 # 1Password
  1487937127 # Craft
  1465439395 # Dark Noise
  1502839586 # Hand Mirror
  904280696 # Things3
  869223134 # KakaoTalk
  1446377255 # Menu World Time
  1534275760 # LanguageTool
  639968404 # Parcel
  1453273600 # Data Jar
  1176895641 # Spark
  1604176982 # One Thing
  1425368544 # Timery
  6450279539 # Second Clock
)
mas install ${apps_app_store[@]}

# install apps with brew cask
apps=(
  slack
  firefox
  google-chrome
  spotify
  iterm2
  visual-studio-code
  karabiner-elements
  discord
  iina
  insomnia
  fork
  docker
  google-chrome-canary
  raycast
  telegram
  keycastr
  handbrake
  notion
  postman
)
echo "installing apps with Cask..."
brew tap homebrew/cask-versions
brew install --cask ${apps[@]}


# echo "Installing karabiner config"
# ln -s ~/workspace/dotfiles/app-configs/karabiner/karabiner.json ~/.config/karabiner/karabiner.json

# install one-thing CLI
npm install -g one-thing
