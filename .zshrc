# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="/Users/eunjae/.oh-my-zsh"

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

source $ZSH/oh-my-zsh.sh

export LANG=en_US.UTF-8

# asdf
. /opt/homebrew/opt/asdf/libexec/asdf.sh

alias rc="vi ~/.zshrc && source ~/.zshrc"

alias gs="git status"
alias gac="git add . && git commit -m"
alias gp="git push"
alias gpl="git pull"
alias gl="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
alias gdf="git diff"
alias gpr="gh pr checkout"
alias gprc="gp && gh pr create --web"
alias gco="git checkout"
function gbrup {
    git branch --set-upstream-to=origin/`git branch --show-current` `git branch --show-current`
}
alias gbase-branch="git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'"
function gmergebase {
    gco `gbase-branch` && gpl && gco - && git merge `gbase-branch`
}
alias greset="git reset --mixed HEAD~1"

alias y="ni"
alias yr="nr"
alias yd="nr dev"
alias ya="ni"
alias yun="nun remove"
alias yt="nr test"
alias ytw="nr test --watch"
alias yl="nr lint"
alias ytc="nr type-check"
alias yb="nr build"
alias ys="nr start"
alias yw="yarn workspace"

alias pn="pnpm"

alias amend="git commit --amend"
alias nevermind="git reset --hard HEAD"
alias clean_node_modules="find . -type d -name "node_modules" -exec rm -rf {} +"

alias nv="nvim"

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
alias lgtm="~/workspace/dotfiles/lgtm"

# bun completions
[ -s "/Users/eunjae/.bun/_bun" ] && source "/Users/eunjae/.bun/_bun"

# Bun
export BUN_INSTALL="/Users/eunjae/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# python
if command -v pyenv 1>/dev/null 2>&1; then
    eval "$(pyenv init -)"
fi
