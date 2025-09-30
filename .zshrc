# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="/Users/$(whoami)/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="spaceship"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to automatically update without prompting.
# DISABLE_UPDATE_PROMPT="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# Caution: this setting can cause issues with multiline prompts (zsh 5.7.1 and newer seem to work)
# See https://github.com/ohmyzsh/ohmyzsh/issues/5765
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

plugins=(zsh-z git)

zstyle ':omz:plugins:git' aliases no

source $ZSH/oh-my-zsh.sh

export LANG=en_US.UTF-8

# asdf
#. /opt/homebrew/opt/asdf/libexec/asdf.sh

alias rc="vi ~/.zshrc && source ~/.zshrc"

alias g="lazygit"
alias gs="git status"
alias gac="git add . && git commit -m"
function gacp() {
    git add .
    git commit -m $1
    git push
}
alias gp="git push"
alias gpl="git pull"
alias gl="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
alias gdf="git diff"
alias gprc="gp && gh pr create --web"
alias gco="git checkout"
alias gbase-branch="git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'"
function gmergebase {
    gco `gbase-branch` && gpl && gco - && git merge `gbase-branch`
}
alias greset="git reset --mixed HEAD~1"
function gcl() {
  git clone "$1"
  local repo_name=$(basename "$1" .git)
  cd "$repo_name"
  cursor .
}
alias gbranch="git rev-parse --abbrev-ref HEAD"
function gupstream() {
  git branch --set-upstream-to=origin/$(gbranch) $(gbranch)
  git pull
}
alias prview="gh pr view --web"
alias repoview="gh repo view --web"

function y() {
  if [[ -n $1 ]]; then
    nr "$@"
  else
    ni
  fi
}
alias yr="nun"
alias yd="npm_install_if_branch_changed && nr dev"
alias ya="ni"
alias yt="nr test"
alias ytw="nr test --watch"
alias yl="nr lint"
alias ytc="nr type-check"
alias yb="nr build"
alias ys="nr start"
alias yw="yarn workspace"

alias amend="git commit --amend --no-edit"
alias nevermind="git reset --hard HEAD"
alias clean_node_modules="find . -type d -name \"node_modules\" -exec rm -rf {} +"
function clean_all() {
  find . -type d -name $1 -exec rm -rf {} +
}

alias d="cd ~/Downloads"
alias f="open ."
alias ytb="youtube-dl"
alias localip="ifconfig -l | xargs -n1 ipconfig getifaddr"
alias localssl_3000="local-ssl-proxy --source 3010 --target 3000 --cert localhost.pem --key localhost-key.pem"
alias localssl_5173="local-ssl-proxy --source 5174 --target 5173 --cert localhost.pem --key localhost-key.pem"
alias localssl_8080="local-ssl-proxy --source 8081 --target 8080 --cert localhost.pem --key localhost-key.pem"
alias ngrok_3000="ngrok http --region=eu --hostname=eunjae.eu.ngrok.io 3000"
alias ngrok_8080="ngrok http --region=eu --hostname=eunjae.eu.ngrok.io 8080"
#alias ngrok_5173="ngrok http --region=eu --hostname=eunjae.eu.ngrok.io 5173"
alias ngrok_5173="ngrok http http://localhost:5173 --region=eu --hostname=eunjae.eu.ngrok.io"
alias ngrok_semrush="ngrok http --region=us --hostname=semrushtest2.ngrok.io 3000"
alias ngrok_smartling="ngrok http --hostname=smartling2.ngrok.app 3000"

alias cal_dir="cd ~/workspace/cal.com"
alias c1="cal_dir && y && yd"
alias c2="cal_dir && g"
alias c3="cal_dir"
alias cal_reset="y && yarn prisma migrate reset -f && yarn workspace @calcom/prisma seed-insights && yarn workspace @calcom/prisma seed-pbac"
alias cal_db="psql postgresql://postgres:@localhost:5432/calendso"
alias cal="zellij attach cal"
alias z_cal="zellij --layout ~/.config/zellij/layouts/cal.kdl"
alias cc="opencode"

export PATH="/Users/$(whoami)/workspace/dotfiles/dots/bin:$PATH"

export PATH="/Users/$(whoami)/workspace/dotfiles/bin:$PATH"

export PATH="/opt/homebrew/bin:$PATH"

# bun completions
[ -s "/Users/$(whoami)/.bun/_bun" ] && source "/Users/$(whoami)/.bun/_bun"

# Bun
export BUN_INSTALL="/Users/$(whoami)/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Docker
export PATH="$PATH:/Applications/Docker.app/Contents/Resources/bin/"
eval "$(mise activate zsh)"

# pnpm
export PNPM_HOME="/Users/eunjae/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

. "$HOME/.atuin/bin/env"

eval "$(atuin init zsh)"

alias things="/Users/eunjae/.local/share/mise/installs/node/22.14.0/bin/things"
export PATH="$PATH:/Users/eunjae/workspace/vchange"
alias rvc="/Users/eunjae/workspace/vchange/rvc"
