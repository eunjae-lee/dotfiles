# How to setup your Mac for web development

@ 5 Oct 2023

Congratulations for getting a Mac for the first time!

This post is going to teach you how to setup your Mac for web development, and
also how to create a `dotfiles` repository to keep your config more
persistently.

## dotfiles

When you develop, you see lots of config files that starts with `.`, like:

- `.env`
- `.prettierrc`
- `.eslintrc`

Files that starts with `.` are hidden in many applications by default. That's a
convention. And there are some system-wide dotfiles that you may want to keep in
your GitHub repository, and use it for your next Mac in the future.

For example, `~/.zshrc` is the most common dotfile you want to keep somewhere.
It contains all the aliases and prompt-related configs, etc. So what we're going
to do is to create a repository on GitHub and name it something like `dotfiles`.
We will create a `.zshrc` file inside the repo, and make a symbolic link at
`~/.zshrc` to this file. It means it seems like there is a file at `~/.zshrc`
but it's actually a link to an actual file like `~/workspace/dotfiles/.zshrc`.
However, we cannot do this yet, because your brand new Mac doesn't have `git`
installed. So let's begin there.

## Configure GitHub SSH key

```sh
echo "Setting up SSH key for GitHub..."
ssh-keygen -t rsa
cat ~/.ssh/id_rsa.pub | pbcopy
open "https://github.com/settings/ssh/new"
```

Run the code above line by line. In case it doesn't work, you can learn more
from
[this link](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account),
which may differ from this.

## Install homebrew

Homebrew is a package manager for Mac. As if you install a Node.js package with
`npm install <package-name>`, you can use Homebrew to install Mac-related
packages.

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

brew update
```

## Install Git

Now that Homebrew is installed, we can install git.

```sh
brew install git
```

## Create dotfiles repo

Personally I keep all the projects at `~/workspace/`. Feel free to use your own
directory name if you want from now on.

```sh
mkdir -p ~/workspace/dotfiles
cd ~/workspace/dotfiles
git init
touch .gitconfig
```

This `.gitconfig` will contain any global git configuration. And let's move the
existing `.zshrc` to this dotfiles repo.

```sh
mv ~/.zshrc ~/workspace/dotfiles/
```

And commit them.

```sh
git add .
git commit -m "initial commit"
```

## Make symbolic links for dotfiles

```sh
rm -f ~/.gitconfig ~/.zshrc

ln -s ~/workspace/dotfiles/.gitconfig ~/.gitconfig
ln -s ~/workspace/dotfiles/.zshrc ~/.zshrc
```

We first remove the dotfiles, and make symbolic links (a.k.a symlinks) to the
ones in our dotfiles repo.

## Install `gh` command

`gh` is a CLI tool from GitHub. It helps you interact with your GitHub
repository easily.

```sh
brew install gh

gh auth login
```

Once you're logged in, let's create a `dotfiles` repo on your GitHub and push
the existing local repository to it.

```sh
cd ~/workspace/dotfiles
gh repo create
```

And then follow the steps from there, and choose to push existing repository to
the newly created remote repository.

## Keeping dotfiles up-to-date

Now that you made the symlinks, whenever you update `~/.zshrc` or
`~/.gitconfig`, the files within the `~/workspace/dotfiles` will change. Then
you need to go to the repo and commit the change from time to time.

## Setup Node.js

By default, MacOS includes Node.js. However, you need a version manager for
Node.js. There are lots of different versions of Node.js and you want to install
many, and want to switch from one to another easily. That's what version
managers are for. There are `nvm` and `nodenv`. Personally I use `asdf`. `asdf`
is not specific to Node.js but it's a general tool to manage versions of many
different things. So we will install `asdf` first, and then install
`asdf-nodejs` plugin.

```sh
brew install asdf
asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git
brew install gnupg
asdf install nodejs 18.18.0
```

Look carefully at the output of those commands. If they tell you to add
something to `~/.zshrc` or to run some command that adds something to it, then
follow all of them.

Let's create a config file for `asdf` so that we can specify a default Node.js
version for us.

```sh
cd ~/workspace/dotfiles
touch .tool-versions

ln -s ~/workspace/dotfiles/.tool-versions ~/.tool-versions
```

Let's open this `.tool-versions` and put `nodejs 18.18.0` as content. With this
config, wherever you are, `18.18.0` will be used by default. When you're in a
folder that contains a local `.tool-versions`, then `asdf` will respect its
version. For example you go to `~/workspace/project-a`, and if there is
`~/workspace/project-a/.tool-versions`, then it will read the Node.js version
from it and try to use it. However, let's say, if the version is "18.0.0" and
it's not installed on your Mac, `asdf` will show you an error message. Then you
can follow the instruction to install `18.0.0` and it will continue to work
again.

## Install applications

Let's install some applications. Here is a list. Feel free to remove if you
don't want or don't recognize.

```sh
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
```

(You need to copy the whole block and run it on the terminal. Not line by line)

```sh
brew tap homebrew/cask-versions
brew install --cask ${apps[@]}
```

Now the command above will install all the apps from the list.

## Install fonts

You can also install fonts with Homebrew.

```sh
brew tap homebrew/cask-fonts
brew install --cask font-jetbrains-mono font-jetbrains-mono-nerd-font font-roboto font-spectral font-noto-sans-cjk
```

The snippet above is an example. Feel free to google and see more fonts.

## Explore other dotfiles

If you go to GitHub and search for `dotfiles`, you will see lots of different
dotfiles repositories from others. If you're adventurous, you may find something
intersting from there.

## Learn more about terminal

If you want to step up with your terminal setup, check out this
[Free course by Wes Bos](https://commandlinepoweruser.com/).

You will learn about Oh My Zsh in this course. Oh My Zsh is a plugin of `zsh`
(which is the default shell in MacOS). Once you intall Oh My Zsh, you can
install plugins of Oh My Zsh which provides more functionalites to your
terminal. However, this step is totally optional.

## Customize your terminal prompt

You can make your terminal prompt more shiny. Not only beautiful, but also it
can display which version of Node.js you're using in your current project, and
more. There are many scripts that do this, but personall I use
[Spaceship](https://github.com/spaceship-prompt/spaceship-prompt). You can
install it via Oh My Zsh, but if you haven't configured it, then you can just
install it with Homebrew too. You can learn more about it on its GitHub repo.
