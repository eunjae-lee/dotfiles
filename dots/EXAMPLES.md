# Migration Examples

This file contains example migrations for common use cases.

## Migration Formats

### Single Migration

A single migration with one provider:

```yaml
provider: sh
command: |
  echo "Hello, World!"
```

### Multiple Migrations (Array)

Multiple migrations in one file, executed sequentially:

```yaml
- provider: sh
  command: |
    echo "Step 1: Preparation"
    mkdir -p ~/.config

- provider: brew
  packages:
    - vim
    - git

- provider: sh
  command: |
    echo "Step 3: Finalization"
```

All migrations in the array are applied in order and tracked as a single unit.

## Shell Commands

### Create Symlinks

```yaml
provider: sh
command: |
  ln -sf "$HOME/.dotfiles/.zshrc" "$HOME/.zshrc"
  ln -sf "$HOME/.dotfiles/.gitconfig" "$HOME/.gitconfig"
  echo "Symlinks created"
```

### Configure Git

```yaml
provider: sh
command: |
  git config --global user.name "Your Name"
  git config --global user.email "your.email@example.com"
  git config --global core.editor "vim"
  git config --global init.defaultBranch "main"
```

### Create Directories

```yaml
provider: sh
command: |
  mkdir -p "$HOME/Projects"
  mkdir -p "$HOME/.config"
  mkdir -p "$HOME/.local/bin"
```

### Install Oh My Zsh

```yaml
provider: sh
command: |
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  else
    echo "Oh My Zsh already installed"
  fi
```

## Homebrew Packages

### Development Tools

```yaml
provider: brew
packages:
  - git
  - vim
  - neovim
  - tmux
  - fzf
  - ripgrep
  - fd
  - bat
  - exa
  - jq
  - htop
```

### Node.js Development

```yaml
provider: brew
packages:
  - node
  - yarn
  - pnpm
```

### Python Development

```yaml
provider: brew
packages:
  - python@3.11
  - pipenv
  - poetry
```

### GUI Applications

```yaml
provider: brew
casks:
  - visual-studio-code
  - iterm2
  - docker
  - spotify
  - slack
  - zoom
```

### Fonts

```yaml
provider: brew
taps:
  - homebrew/cask-fonts
casks:
  - font-fira-code
  - font-jetbrains-mono
  - font-source-code-pro
```

### Complete Development Setup

```yaml
provider: brew
taps:
  - homebrew/cask-fonts
packages:
  - git
  - neovim
  - tmux
  - fzf
  - ripgrep
  - fd
  - node
  - python@3.11
casks:
  - visual-studio-code
  - iterm2
  - docker
  - font-fira-code
```

## Mac App Store

### Essential Apps

```yaml
provider: mas
apps:
  - name: "Xcode"
    id: 497799835
  - name: "1Password"
    id: 1333542190
  - name: "Slack"
    id: 803453959
```

### Productivity Apps

```yaml
provider: mas
apps:
  - name: "Things 3"
    id: 904280696
  - name: "Bear"
    id: 1091189122
  - name: "Magnet"
    id: 441258766
```

## Combined Examples

### Complete Machine Setup

You can organize your setup in multiple ways:

#### Option 1: Separate Migration Files

Create multiple migration files for better organization:

**`20250930_100000_install_homebrew.yml`:**
```yaml
provider: sh
command: |
  if ! command -v brew &> /dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  brew update
```

**`20250930_100100_install_cli_tools.yml`:**
```yaml
provider: brew
packages:
  - git
  - neovim
  - tmux
  - fzf
  - ripgrep
  - fd
  - bat
  - jq
```

#### Option 2: Single File with Multiple Migrations

Combine related steps in one file using array format:

**`20250930_100000_complete_setup.yml`:**
```yaml
- provider: sh
  command: |
    if ! command -v brew &> /dev/null; then
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    brew update

- provider: brew
  packages:
    - git
    - neovim
    - tmux
    - fzf
    - ripgrep
    - fd
    - bat
    - jq

- provider: brew
  casks:
    - visual-studio-code
    - iterm2
    - docker

- provider: sh
  command: |
    git config --global user.name "Your Name"
    git config --global user.email "your@email.com"
    git config --global core.editor "nvim"

- provider: sh
  command: |
    ln -sf "$HOME/.dotfiles/.zshrc" "$HOME/.zshrc"
    ln -sf "$HOME/.dotfiles/.gitconfig" "$HOME/.gitconfig"
    echo "Setup complete!"
```

#### 3. `20250930_100200_install_apps.yml`

```yaml
provider: brew
casks:
  - visual-studio-code
  - iterm2
  - docker
```

#### 4. `20250930_100300_configure_git.yml`

```yaml
provider: sh
command: |
  git config --global user.name "Your Name"
  git config --global user.email "your.email@example.com"
  git config --global core.editor "nvim"
  git config --global init.defaultBranch "main"
  git config --global pull.rebase false
```

#### 5. `20250930_100400_create_symlinks.yml`

```yaml
provider: sh
command: |
  ln -sf "$HOME/.dotfiles/.zshrc" "$HOME/.zshrc"
  ln -sf "$HOME/.dotfiles/.gitconfig" "$HOME/.gitconfig"
  ln -sf "$HOME/.dotfiles/.tmux.conf" "$HOME/.tmux.conf"
  ln -sf "$HOME/.dotfiles/config/nvim" "$HOME/.config/nvim"
```

#### 6. `20250930_100500_install_mas_apps.yml`

```yaml
provider: mas
apps:
  - name: "Xcode"
    id: 497799835
```

## When to Use Arrays vs Separate Files

### Use Separate Files When:
- Migrations are logically independent
- You might want to apply them selectively
- They can fail independently
- Better for tracking in git history

### Use Arrays When:
- Steps must be executed together as a unit
- They represent a single logical change
- Order is critical and steps depend on each other
- You want atomic application (all-or-nothing)

## Tips

1. **Keep migrations focused**: One logical task per migration file
2. **Name descriptively**: Use clear names like `install-docker` not `setup`
3. **Make idempotent**: Check if things exist before creating/installing
4. **Test with dry-run**: Always run `dots apply --dry-run` first
5. **Commit incrementally**: Commit each working migration
6. **Document complex commands**: Add comments in shell commands
7. **Use arrays for related steps**: Group tightly coupled operations in one file
8. **Separate independent tasks**: Keep unrelated operations in different files