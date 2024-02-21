echo "Setting up SSH key for GitHub..."
ssh-keygen -t rsa
cat ~/.ssh/id_rsa.pub | pbcopy
open "https://github.com/settings/ssh/new"

echo "Installing xcode-stuff..."

if test ! $(which brew); then
  echo "Installing homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

brew update

echo "Installing Git..."
brew install git gh

echo "Setting up dotfiles..."
mkdir -p ~/workspace/
git clone git@github.com:eunjae-lee/dotfiles.git ~/workspace/dotfiles

ln -s ~/workspace/dotfiles/.gitconfig ~/.gitconfig

echo "Setting up zsh..."
chsh -s /bin/zsh

# https://unix.stackexchange.com/questions/557486/allowing-comments-in-interactive-zsh-commands
setopt interactive_comments

sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

git clone https://github.com/spaceship-prompt/spaceship-prompt.git "$ZSH_CUSTOM/themes/spaceship-prompt" --depth=1
ln -s "$ZSH_CUSTOM/themes/spaceship-prompt/spaceship.zsh-theme" "$ZSH_CUSTOM/themes/spaceship.zsh-theme"

git clone https://github.com/agkozak/zsh-z $ZSH_CUSTOM/plugins/zsh-z

rm .zshrc
ln -s ~/workspace/dotfiles/.zshrc .zshrc

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
)
mas install ${apps_app_store[@]}

echo "Setting up node.js..."
# asdf
# https://gist.github.com/Grawl/461c7c1acfcf7e2ecbf99ce9fed40c31
brew install asdf
# echo ". /usr/local/opt/asdf/libexec/asdf.sh" >> ~/.zshrc
asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git
brew install gnupg
asdf install nodejs latest

asdf plugin add alias https://github.com/andrewthauer/asdf-alias.git
asdf alias node 18 18.16.0

ln -s ~/workspace/dotfiles/.tool-versions ~/.tool-versions

echo "installing packages with Brew...."
packages=(
  yarn
  rg
  lazygit
  wget
  http-server
  jq
  m-cli # https://github.com/rgcr/m-cli
  switchaudio-osx # https://github.com/deweller/switchaudio-osx
  slimhud # https://github.com/AlexPerathoner/SlimHUD
  shortcat # https://shortcat.app/
  rustup
  pnpm
  neovim
)
brew install ${packages[@]}

# configure neovim
rm -rf ~/.local/share/nvim
rm -rf ~/.local/state/nvim
rm -rf ~/.cache/nvim
mv ~/.config/nvim ~/.config/nvim.backup
git clone --depth 1 https://github.com/AstroNvim/AstroNvim ~/.config/nvim
ln -s ~/workspace/dotfiles/config/AstroNvim ~/.config/nvim/lua/user

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

# configure raycast
ln -s ~/workspace/dotfiles/app-configs/raycast-scripts ~/workspace/raycast-scripts

echo "installing apps with Cask..."
brew tap homebrew/cask-versions
brew install --cask ${apps[@]}

brew tap homebrew/cask-fonts
brew install --cask font-jetbrains-mono font-jetbrains-mono-nerd-font font-roboto font-spectral font-noto-sans-cjk font-cascadia-code font-cascadia-code-pl font-cascadia-mono font-cascadia-mono-pl font-monaspace font-fira-code

echo "Installing karabiner config"
ln -s ~/workspace/dotfiles/app-configs/karabiner/karabiner.json ~/.config/karabiner/karabiner.json


