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

  docker
)
echo "installing apps with Cask..."
brew install --cask ${apps[@]}

# Install Ice (https://github.com/jordanbaird/Ice)
brew install jordanbaird-ice

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

extensions=(
  aaron-bond.better-comments
  astro-build.astro-vscode
  beardedbear.beardedtheme
  bibhasdn.unique-lines
  britesnow.vscode-toggle-quotes
  christian-kohler.path-intellisense
  dbaeumer.vscode-eslint
  donjayamanne.githistory
  dracula-theme.theme-dracula
  esbenp.prettier-vscode
  fabiospampinato.vscode-open-in-github
  formulahendry.auto-rename-tag
  github.copilot
  github.copilot-chat
  github.vscode-github-actions
  k--kato.intellij-idea-keybindings
  mikestead.dotenv
  ms-playwright.playwright
  pepri.subtitles-editor
  pomdtr.excalidraw-editor
  sebsojeda.vscode-svx
  svelte.svelte-vscode
  tldraw-org.tldraw-vscode
  vitest.explorer
  vue.volar
  wmaurer.change-case
  yatki.vscode-surround
  yoavbls.pretty-ts-errors
)
for extension in "${extensions[@]}"; do
  code --install-extension "$extension"
done

# echo "Installing karabiner config"
# ln -s ~/workspace/dotfiles/app-configs/karabiner/karabiner.json ~/.config/karabiner/karabiner.json

# install one-thing CLI
npm install -g one-thing
