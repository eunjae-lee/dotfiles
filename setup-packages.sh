#!/bin/zsh

echo "installing packages with Brew...."
packages=(
  yarn
  rg
  lazygit
  wget
  # http-server
  jq
  m-cli # https://github.com/rgcr/m-cli
  switchaudio-osx # https://github.com/deweller/switchaudio-osx
  # shortcat # https://shortcat.app/
  rustup
  ffmpeg
  git-delta
  libheif # heif-convert
)
brew install ${packages[@]}

echo "installing fonts..."
brew install --cask font-jetbrains-mono font-jetbrains-mono-nerd-font font-roboto font-spectral font-noto-sans-cjk font-cascadia-code font-cascadia-code-pl font-cascadia-mono font-cascadia-mono-pl font-monaspace font-fira-code

# install xc
# https://xcfile.dev/
brew tap joerdav/xc
brew install xc
