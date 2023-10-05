# How to setup your Mac for web development

@ 5 Oct 2023

Congratulations on getting your first Mac!

Congratulations on getting your first Mac! This post will guide you through setting up your Mac for web development and creating a ﻿`dotfiles` repository to store your configurations more persistently.

## dotfiles

When you develop, you often come across configuration files that start with a period (.), such as:

- `.env`
- `.prettierrc`
- `.eslintrc`

Files starting with a period are hidden by default in many applications. This is a convention. There are also system-wide dotfiles that you may want to store in your GitHub repository and use for future Mac setups.

For example, `﻿~/.zshrc` is a common dotfile that contains aliases and prompt-related configurations. To manage these dotfiles, we will create a repository on GitHub called ﻿dotfiles. Inside this repository, we will create a ﻿`.zshrc` file and create a symbolic link at `﻿~/.zshrc` that points to this file. This way, it appears as though there is a file at `﻿~/.zshrc`, but it is actually linked to the file `﻿~/workspace/dotfiles/.zshrc`.

However, before we proceed, we need to install `﻿git` on your new Mac. Let's start there.

## Configure GitHub SSH key

```sh
echo "Setting up SSH key for GitHub..."
ssh-keygen -t rsa
cat ~/.ssh/id_rsa.pub | pbcopy
open "https://github.com/settings/ssh/new"
```

Run the above code line by line. If it doesn't work, you can learn more from
[this link](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account),
which may have different instructions.

## Install homebrew

Homebrew is a package manager for Mac. Similar to installing a Node.js package with `﻿npm install <package-name>`, you can use Homebrew to install Mac-related packages.

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

brew update
```

## Install Git

Now that Homebrew is installed, we can install `git`.

```sh
brew install git
```

## Create dotfiles repo

I prefer keeping all my projects in `﻿~/workspace/`. You can choose your own directory name if you prefer.

```sh
mkdir -p ~/workspace/dotfiles
cd ~/workspace/dotfiles
git init
touch .gitconfig
```

The `.gitconfig` will contain any global git configuration. Let's move the
existing `.zshrc` to this dotfiles repo.

```sh
mv ~/.zshrc ~/workspace/dotfiles/
```

Now, let's commit them.

```sh
git add .
git commit -m "initial commit"
```

## Create symbolic links for dotfiles

```sh
rm -f ~/.gitconfig ~/.zshrc

ln -s ~/workspace/dotfiles/.gitconfig ~/.gitconfig
ln -s ~/workspace/dotfiles/.zshrc ~/.zshrc
```

First, we remove the existing dotfiles and then create symbolic links (symlinks) to the ones in our dotfiles repository.

## Install `gh` command

`gh` is a command-line tool from GitHub that makes it easy to interact with your GitHub repository.

```sh
brew install gh

gh auth login
```

Once you're logged in, let's create a ﻿`dotfiles` repository on your GitHub account and push the existing local repository to it.

```sh
cd ~/workspace/dotfiles
gh repo create
```

Follow the steps provided and choose to push the existing repository to the newly created GitHub repository.

## Keeping dotfiles up-to-date

After creating symlinks, any updates made to `﻿~/.zshrc` or `﻿~/.gitconfig` will automatically change the corresponding files in `﻿~/workspace/dotfiles`. Therefore, you will need to periodically go to the repository and commit the changes.

## Setup Node.js

Although Node.js is included by default in MacOS, you need a version manager for Node.js. There are many version managers available, such as ﻿`nvm` and ﻿`nodenv`. Personally, I prefer using ﻿`asdf`, which is a general tool for managing versions of various software. To begin, install ﻿`asdf` and then add the `﻿asdf-nodejs` plugin using the following commands:

```sh
brew install asdf
asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git
brew install gnupg
asdf install nodejs 18.18.0
```

Carefully review the output of these commands. If they instruct you to add something to ﻿`~/.zshrc` or run a command that modifies it, make sure to follow those instructions.

Next, let's create a configuration file for ﻿asdf that will allow us to specify a default Node.js version. Execute the following commands:

```sh
cd ~/workspace/dotfiles
touch .tool-versions

ln -s ~/workspace/dotfiles/.tool-versions ~/.tool-versions
```

Open the `﻿.tool-versions` file and set ﻿`nodejs 18.18.0` as its content. With this configuration, ﻿`18.18.0` will be the default Node.js version wherever you are. When you navigate to a folder that contains a local `﻿.tool-versions` file, ﻿asdf will use the specified version from that file. For example, if you go to `﻿~/workspace/project-a` and there is a `﻿~/workspace/project-a/.tool-versions` file, ﻿asdf will read the Node.js version specified in that file and attempt to use it. However, if the version is `18.0.0` and it is not installed on your Mac, ﻿`asdf` will display an error message. In that case, you can follow the instructions to install version ﻿`18.0.0`, and `﻿asdf` will resume working.

## Install applications

To install applications, use the following list. Feel free to remove any that you don't want or recognize:

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

Copy the entire block and run it in the terminal, rather than line by line. This command will install all the apps from the list.

```sh
brew tap homebrew/cask-versions
brew install --cask ${apps[@]}
```

## Install fonts

You can also install fonts using Homebrew:

```sh
brew tap homebrew/cask-fonts
brew install --cask font-jetbrains-mono font-jetbrains-mono-nerd-font font-roboto font-spectral font-noto-sans-cjk
```

The snippet above is an example. Feel free to Google and explore more fonts.

## Explore other dotfiles

If you visit GitHub and search for ﻿`dotfiles`, you will find numerous repositories from others. If you're adventurous, you might discover something interesting there.

## Learn more about terminal

If you want to enhance your terminal setup, check out this
[Free course by Wes Bos](https://commandlinepoweruser.com/).

The course covers Oh My Zsh, a plugin for `﻿zsh`, which is the default shell in MacOS. By installing Oh My Zsh, you can add plugins that provide additional functionalities to your terminal. However, this step is optional.

## Customize your terminal prompt

You can make your terminal prompt more visually appealing. Not only can it be beautiful, but it can also display the version of Node.js you're using in your current project and more. There are many scripts that can achieve this, but personally, I use [Spaceship](https://github.com/spaceship-prompt/spaceship-prompt). You can install it via Oh My Zsh, or if you haven't configured Oh My Zsh, you can also install it with Homebrew. For more information, you can visit its GitHub repository.
