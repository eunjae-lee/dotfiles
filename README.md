# dotfiles

Personal dotfiles and system setup using a minimal migration-driven approach.

## 🚀 Quick Start

```bash
# Preview what would be installed
./setup apply --dry-run

# Generate config.yml without installing anything
./setup apply --config-only  

# Install everything
./setup apply
```

## 📋 What gets installed

- **Homebrew**: Package manager + 36 packages + 20 casks + fonts
- **Apps**: 11 Mac App Store apps + 24 VSCode extensions
- **Development**: Node.js, Python, Rust via asdf
- **Shell**: Zsh + Oh My Zsh + spaceship theme + plugins  
- **Tools**: Git, GitHub CLI, SSH keys, tmux, zellij, PM2
- **Dotfiles**: Symlinked configurations for all apps

## 🛠 Commands

```bash
./setup apply [--dry-run|--config-only]    # Apply migrations
./setup create <name>                       # Create new migration
./setup validate                           # Validate configuration
```

## 🧪 Testing

The setup system includes a comprehensive unit test suite to ensure reliability:

```bash
# Install Ruby dependencies
bundle install --path vendor/bundle

# Run all tests
bundle exec rspec

# Run specific test files
bundle exec rspec spec/config_spec.rb

# Validate setup functionality
./setup validate

# Test dry-run functionality
./setup apply --dry-run
```

**Test Coverage:**
- Configuration parsing and merging
- Migration loading and execution
- CLI command handling
- Provider-specific logic (Homebrew, Apps, etc.)
- Dry-run and validation modes

## 📁 Structure

```
setup                 # Main CLI script
config.yml           # Single source of truth (generated)
migrations/          # Migration files
lib/                 # Migration system
spec/                # Unit tests (RSpec)
legacy/              # Old setup scripts (deprecated)
app-configs/         # Application configurations
Gemfile              # Ruby dependencies
```

## 🔄 Migration System

This repo uses a custom migration system that:

- Tracks all changes in `config.yml`
- Provides domain-specific configuration merging
- Supports dry-run and config-only modes
- Validates configurations before applying
- Only runs new migrations (idempotent)

See [`IMPLEMENTATION.md`](IMPLEMENTATION.md) for technical details.

## 📦 Legacy Scripts

Old setup scripts have been moved to [`legacy/`](legacy/) directory. The migration system provides the same functionality with better organization and tracking.

