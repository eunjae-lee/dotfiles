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

#export PATH="/Users/$(whoami)/workspace/dotfiles/dots/bin:$PATH"

export PATH="/Users/$(whoami)/workspace/dotfiles/bin:$PATH"


plugins=(zsh-z git auto-notify)

zstyle ':omz:plugins:git' aliases no

source $ZSH/oh-my-zsh.sh

export LANG=en_US.UTF-8

export EDITOR=vi

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
  zed .
}
alias gbranch="git rev-parse --abbrev-ref HEAD"
function gupstream() {
  git branch --set-upstream-to=origin/$(gbranch) $(gbranch)
  git pull
}
alias prview="gh pr view --web"
alias repoview="gh repo view --web"

function _detect_pm() {
  local dir="$PWD"
  while [[ "$dir" != "/" ]]; do
    [[ -f "$dir/bun.lockb" || -f "$dir/bun.lock" ]] && echo "bun" && return
    [[ -f "$dir/pnpm-lock.yaml" ]] && echo "pnpm" && return
    [[ -f "$dir/yarn.lock" ]] && echo "yarn" && return
    [[ -f "$dir/package-lock.json" ]] && echo "npm" && return
    dir="$(dirname "$dir")"
  done
  echo "npm"
}

function _pm_install() {
  $(_detect_pm) install "$@"
}

function _pm_run() {
  local pm="$(_detect_pm)"
  if [[ "$pm" == "npm" ]]; then
    npm run "$@"
  else
    $pm run "$@"
  fi
}

function y() {
  if [[ -n $1 ]]; then
    _pm_run "$@"
  else
    _pm_install
  fi
}
alias yd="_pm_run dev"
alias ya="_pm_install"
alias yt="_pm_run test"
alias ytw="_pm_run test --watch"
alias yl="_pm_run lint"
alias ytc="_pm_run type-check"
alias yb="_pm_run build"
alias ys="_pm_run start"
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

alias cal_dir="cd ~/workspace/cal"
alias c1="cal_dir && y && yd"
alias c2="cal_dir && g"
alias c3="cal_dir"
alias cal_reset="y && yarn prisma migrate reset -f && yarn workspace @calcom/prisma seed-insights"
alias cal_db="psql postgresql://postgres:@localhost:5432/calendso"
alias zcal_old="cd ~/workspace/cal.com && zellij --layout ~/workspace/dotfiles/app-configs/zellij/cal2_old.kdl"
alias zcal="cd ~/workspace/cal && zellij --layout ~/workspace/dotfiles/app-configs/zellij/cal2_new.kdl"
alias zmini="zellij --layout ~/workspace/dotfiles/app-configs/zellij/mac_mini.kdl"
alias cc="claude"
alias zl="zellij"

export PATH="/opt/homebrew/bin:$PATH"


# Docker
export PATH="$PATH:/Applications/Docker.app/Contents/Resources/bin/"

# mise-en-place (now in .zprofile for login shell compatibility)
# eval "$(mise activate zsh)"

# pnpm
export PNPM_HOME="/Users/eunjae/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# . "$HOME/.atuin/bin/env"  # (disabled; brew install uses `atuin init zsh`)

eval "$(atuin init zsh)"

alias things="/Users/eunjae/.local/share/mise/installs/node/22.14.0/bin/things"

# Added by Antigravity
export PATH="/Users/eunjae/.antigravity/antigravity/bin:$PATH"


# OpenCode Config - add bin directory to PATH
export PATH="$HOME/.config/opencode/bin:$PATH"

# ghostty
export PATH="/Applications/Ghostty.app/Contents/MacOS:$PATH"

alias tailscale="/Applications/Tailscale.app/Contents/MacOS/Tailscale"

psqldev() {
  if [[ ! -f .env ]]; then
    echo ".env not found"
    return 1
  fi

  local DATABASE_URL

  DATABASE_URL=$(grep -E '^DATABASE_URL=' .env | sed 's/^DATABASE_URL=//' | tr -d '"')

  if [[ -z "$DATABASE_URL" ]]; then
    echo "DATABASE_URL not found in .env"
    return 1
  fi

  psql "$DATABASE_URL"
}

alias ccc="security unlock-keychain && claude"

export PATH="$HOME/.local/bin:$PATH"

ztc() {
  local sessions
  sessions=$(zellij list-sessions 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g')

  if echo "$sessions" | grep -q '^everything.*EXITED'; then
    zellij delete-session everything
    zellij -s everything -n ~/workspace/dotfiles/app-configs/zellij/everything.kdl
  elif echo "$sessions" | grep -q '^everything'; then
    zellij attach everything
  else
    zellij -s everything -n ~/workspace/dotfiles/app-configs/zellij/everything.kdl
  fi
}

zfc() {
  local sessions
  sessions=$(zellij list-sessions 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g')

  if echo "$sessions" | grep -q '^flowcat.*EXITED'; then
    zellij delete-session flowcat
    zellij -s flowcat -n ~/workspace/dotfiles/app-configs/zellij/flowcat.kdl
  elif echo "$sessions" | grep -q '^flowcat'; then
    zellij attach flowcat
  else
    zellij -s flowcat -n ~/workspace/dotfiles/app-configs/zellij/flowcat.kdl
  fi
}

zpc() {
  local sessions
  sessions=$(zellij list-sessions 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g')

  if echo "$sessions" | grep -q '^pi_workspace.*EXITED'; then
    zellij delete-session pi_workspace
    zellij -s pi_workspace -n ~/workspace/dotfiles/app-configs/zellij/pi_workspace.kdl
  elif echo "$sessions" | grep -q '^pi_workspace'; then
    zellij attach pi_workspace
  else
    zellij -s pi_workspace -n ~/workspace/dotfiles/app-configs/zellij/pi_workspace.kdl
  fi
}

znc() {
  local sessions
  sessions=$(zellij list-sessions 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g')

  if echo "$sessions" | grep -q '^nanoclaw.*EXITED'; then
    zellij delete-session nanoclaw
    zellij -s nanoclaw -n ~/workspace/dotfiles/app-configs/zellij/nanoclaw.kdl
  elif echo "$sessions" | grep -q '^nanoclaw'; then
    zellij attach nanoclaw
  else
    zellij -s nanoclaw -n ~/workspace/dotfiles/app-configs/zellij/nanoclaw.kdl
  fi
}

zgc() {
  local sessions
  sessions=$(zellij list-sessions 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g')

  if echo "$sessions" | grep -q '^glowcat .*EXITED'; then
    zellij delete-session glowcat
    zellij -s glowcat -n ~/workspace/dotfiles/app-configs/zellij/glowcat.kdl
  elif echo "$sessions" | grep -q '^glowcat '; then
    zellij attach glowcat
  else
    zellij -s glowcat -n ~/workspace/dotfiles/app-configs/zellij/glowcat.kdl
  fi
}


alias claude-mem='bun "/Users/eunjae/.claude/plugins/cache/thedotmack/claude-mem/10.5.2/scripts/worker-service.cjs"'

alias mini="ssh eunjae@eunjaes-mac-mini-3.tail93e3.ts.net"

alias update_cmux="brew untap eunjae-lee/cmux && brew tap eunjae-lee/cmux && brew reinstall --cask cmux-fork && xattr -cr /Applications/cmux.app"
