echo "Setting up SSH key for GitHub..."
ssh-keygen -t rsa
cat ~/.ssh/id_rsa.pub | pbcopy
open "https://github.com/settings/ssh/new"

echo "Installing xcode-stuff..."

if test ! $(which brew); then
  echo "Installing homebrew..."
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

brew update

echo "Installing Git..."
brew install git gh

echo "Setting up dotfiles..."
git clone git@github.com:eunjae-lee/dotfiles.git .dotfiles

ln -s .dotfiles/.gitconfig .gitconfig

echo "Setting up zsh..."
chsh -s /bin/zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

git clone https://github.com/spaceship-prompt/spaceship-prompt.git "$ZSH_CUSTOM/themes/spaceship-prompt" --depth=1
ln -s "$ZSH_CUSTOM/themes/spaceship-prompt/spaceship.zsh-theme" "$ZSH_CUSTOM/themes/spaceship.zsh-theme"

git clone https://github.com/agkozak/zsh-z $ZSH_CUSTOM/plugins/zsh-z

rm .zshrc
ln -s ~/.dotfiles/.zshrc .zshrc

echo "Setting up node.js..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash
git clone https://github.com/lukechilds/zsh-nvm "$ZSH_CUSTOM/plugins/zsh-nvm" --depth=1

echo "Setting up yarn..."
brew install tophat/bar/yvm

brew install wget

apps=(
  firefox
  google-chrome
  spotify
  iterm2
  visual-studio-code
  karabiner-elements
  discord
  iina
  insomnia
)

echo "installing apps with Cask..."
brew install --cask ${apps[@]}

brew tap homebrew/cask-fonts
brew install --cask font-jetbrains-mono

