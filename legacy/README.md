# Legacy Setup Scripts

This directory contains the original shell-based setup scripts that were used before migrating to the new migration-driven system.

## ⚠️ These scripts are deprecated

**Use the new migration system instead:**

```bash
# See what would be installed
./setup apply --dry-run

# Generate config.yml without installing
./setup apply --config-only  

# Install everything
./setup apply
```

## What's in here

These legacy scripts have been converted into proper migrations:

| Legacy Script | Migration | Description |
|---------------|-----------|-------------|
| `setup-homebrew.sh` | `20250922104120_homebrew_install.yml` | Install Homebrew |
| `setup-packages.sh` | `20250922104141_brew_packages.yml` | Brew packages & fonts |
| `setup-apps.sh` | `20250922104307_apps_install.yml` | Mac App Store & cask apps |
| `setup-git.sh` | `20250922104342_git_setup.yml` | Git, GitHub CLI, SSH keys |
| `setup-dotfiles.sh` | `20250922104405_dotfiles_setup.yml` | Clone repos & symlinks |
| `setup-node.sh` | `20250922104428_nodejs_asdf.yml` | Node.js via asdf |
| `setup-python.sh` | `20250922104428_python_setup.yml` | Python & PyTorch |
| `setup-rust.sh` | `20250922104429_rust_setup.yml` | Rust via asdf |
| `setup-zsh.sh` | `20250922104507_zsh_setup.yml` | Zsh, Oh My Zsh, themes |
| `setup-cli.sh` | `20250922104508_cli_tools.yml` | PM2 ecosystem |
| `setup-tmux.sh` | `20250922104508_tmux_setup.yml` | tmux & TPM |
| `setup-zellij.sh` | `20250922104508_zellij_setup.yml` | zellij & layouts |

## Why migrate?

The new system provides:

- **Single source of truth**: All config in `config.yml`
- **Provider-based merging**: Smart handling of package lists, configs, etc.
- **Dry-run support**: See what would happen before running
- **Config-only mode**: Generate config without installing
- **Validation**: Ensure configurations are valid
- **Incremental updates**: Only run new migrations

## Migration benefits

- From ~2000+ lines of scattered shell scripts
- To ~350 lines of structured Ruby code
- With comprehensive configuration tracking
- And domain-specific merge logic