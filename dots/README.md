# Dots - Dotfiles Migration Manager

A Ruby CLI tool for managing dotfiles migrations across multiple machines using a migration-based approach similar to database migrations.

## Features

- **Migration-based approach**: Track configuration changes over time with timestamped migration files
- **Multiple providers**: Support for shell commands, Homebrew, Mac App Store, git repositories, and symlinks
- **Declarative schema validation**: Expressive DSL for configuration validation with helpful error messages
- **Idempotency**: Migrations are tracked and checksummed to prevent duplicate applications
- **Dry-run mode**: Preview changes before applying them
- **Fake mode**: Mark migrations as applied without executing them
- **Interactive commands**: Support for user input during migrations
- **Version controlled**: Migration files are committed to git while state is kept local

## Installation

```bash
cd dots
bundle install --path vendor/bundle
```

Add to your PATH (recommended):
```bash
# Add to your ~/.zshrc or ~/.bashrc
export PATH="$PATH:/path/to/dotfiles/dots/bin"
```

Or create a symlink:
```bash
ln -s /path/to/dotfiles/dots/bin/dots /usr/local/bin/dots
```

The `dots` command will automatically use bundler to load the required gems.

## Quick Start

```bash
# Navigate to your dotfiles directory
cd ~/dotfiles

# Create your first migration
dots create_migration setup-vim

# Edit the generated migration file
vim migrations/20250930_143022_setup-vim.yml

# Preview what will be applied
dots apply --dry-run

# Apply migrations
dots apply

# Apply without confirmation prompt
dots apply --yes

# Check status
dots status
```

**Note:** The `migrations/` directory is created in your current working directory. Run `dots` commands from your dotfiles repository root.

## Commands

### `dots create_migration NAME`

Creates a new migration file with a timestamp prefix.

```bash
dots create_migration install-vim
# Created: migrations/20250930_143022_install-vim.yml

dots create_migration --help  # Show help
```

### `dots apply [OPTIONS]`

Apply pending migrations.

**Options:**
- `-d, --dry-run` - Preview migrations without applying them
- `-y, --yes` - Skip confirmation prompt
- `-f, --fake` - Mark migrations as applied without executing them

```bash
dots apply              # Apply with confirmation
dots apply --dry-run    # Preview only
dots apply --yes        # Auto-confirm
dots apply --fake       # Mark as applied without running
```

### `dots exec FILE`

Execute a single migration file without tracking it in state. Useful for testing migrations.

```bash
dots exec migrations/test.yml
dots exec /path/to/migration.yml
```

### `dots status`

Show applied and pending migration counts.

```bash
dots status
```

### `dots help [COMMAND]`

Show help for a command.

```bash
dots help
dots help apply
dots help create_migration
```

## Migration File Format

Migration files are YAML files that can contain either:
- A single migration (hash with `provider` key)
- Multiple migrations (array of hashes, each with `provider` key)

**Single Migration:**
```yaml
# Migration: Setup Vim
provider: sh
command: |
  echo "Setting up Vim"
```

**Multiple Migrations:**
```yaml
# Migration: Full Setup
- provider: sh
  command: echo "Step 1"

- provider: brew
  packages:
    - vim

- provider: sh
  command: echo "Done"
```

## Providers

### Shell Provider (sh)

Execute shell commands with full bash support.

```yaml
provider: sh
command: |
  ln -sf "$HOME/.dotfiles/vimrc" "$HOME/.vimrc"
  echo "Vim configured"
```

**Options:**
- `command` (required): Shell command to execute
- `interactive: true` (optional): Allow user input (read prompts)

**Interactive Example:**
```yaml
provider: sh
interactive: true
command: |
  read -p "Enter your name: " name
  echo "Hello, $name!"
```

**Features:**
- Tilde (`~`) expansion in paths
- Full bash syntax support
- Captures stdout/stderr
- Interactive mode for user input

### Symlink Provider (symlink)

Create symbolic links with automatic directory creation.

```yaml
provider: symlink
links:
  - source: "~/workspace/dotfiles/.gitconfig"
    target: "~/.gitconfig"
  - source: "~/workspace/dotfiles/.zshrc"
    target: "~/.zshrc"
    force: true  # Delete target if it exists
```

**Options:**
- `links` (required): Array of link objects
  - `source` (required): Path to source file
  - `target` (required): Path where symlink will be created
  - `force` (optional): Delete existing target file/directory

**Features:**
- Tilde (`~`) expansion
- Automatic parent directory creation
- Detects if symlink already exists
- `force` option to replace existing files

### Repository Provider (repo)

Clone git repositories with automatic parent directory creation.

```yaml
provider: repo
repos:
  - url: git@github.com:user/dotfiles.git
    path: "~/workspace/dotfiles"
  - url: https://github.com/user/project.git
    path: "~/projects/project"
```

**Options:**
- `repos` (required): Array of repository objects
  - `url` (required): Git repository URL
  - `path` (required): Local path to clone to

**Features:**
- Skips if repository already exists
- Creates parent directories automatically
- Supports SSH and HTTPS URLs

### Homebrew Provider (brew)

Install Homebrew packages, casks, and taps.

```yaml
provider: brew
taps:
  - homebrew/cask-fonts
packages:
  - vim
  - tmux
  - git
casks:
  - iterm2
  - visual-studio-code
```

**Options:**
- `taps` (optional): Array of tap names
- `packages` (optional): Array of package names
- `casks` (optional): Array of cask names
- At least one of the above is required

**Features:**
- Checks if already installed (idempotent)
- Skips installed packages
- Installs in order: taps → packages → casks

### Mac App Store Provider (mas)

Install Mac App Store applications.

```yaml
provider: mas
apps:
  - name: "Xcode"
    id: 497799835
  - name: "1Password"
    id: 1333542190
  - 409183694  # Keynote (shorthand format)
```

**Options:**
- `apps` (required): Array of apps (two formats supported)
  - Full format: `{ name: "App Name", id: 123456 }`
  - Shorthand format: Just the numeric ID

**Requirements:**
- `mas` CLI: `brew install mas`
- Signed into Mac App Store

**Finding App IDs:**
```bash
mas search Xcode
mas list
```

## Error Handling

The tool provides helpful, colored error messages with:

- **Red errors** for failures
- **Yellow warnings** for non-critical issues
- **Green success** messages
- **Unknown property detection** catches typos
- **Separate error section** groups all validation errors together

**Example Error Output:**
```
Found 2 pending migration(s):
  - valid.yml: Install Homebrew 2 package(s)
  - invalid.yml: Has validation errors

ERRORS:
  invalid.yml:
    Validation failed for invalid.yml:
      - Link at index 0: Unknown properties: sourceee
      - Link at index 0: Missing or invalid 'source'
```

## State Management

- **State file**: `migrations/.state.yml` (in your working directory)
- **Automatically gitignored**: Added to `.gitignore`
- **Machine-specific**: Each machine tracks its own applied migrations
- **Checksums**: Detects if migrations are modified after being applied

**State file format:**
```yaml
---
- migration: 20250930_143022_install-vim.yml
  checksum: abc123def456...
```

## Workflow Examples

### Initial Setup on Primary Machine

```bash
cd ~/dotfiles

# Create migrations
dots create_migration symlinks
```

Edit `migrations/20250930_120000_symlinks.yml`:
```yaml
# Migration: Setup Symlinks
provider: symlink
links:
  - source: "~/workspace/dotfiles/.gitconfig"
    target: "~/.gitconfig"
  - source: "~/workspace/dotfiles/.zshrc"
    target: "~/.zshrc"
```

```bash
# Apply and commit
dots apply
git add migrations/
git commit -m "Add symlink migration"
git push
```

### Setup on New Machine

```bash
# Clone dotfiles
git clone <your-repo> ~/dotfiles
cd ~/dotfiles

# Install dependencies
cd dots && bundle install --path vendor/bundle && cd ..

# Apply all migrations
dots apply --yes

# Everything is now set up!
```

### Testing a Migration

```bash
# Test without adding to state
dots exec migrations/test.yml

# If it works, apply normally
dots apply
```

### Manual Setup Already Done

If you've already set things up manually and want to track them:

```bash
# Mark migrations as applied without running them
dots apply --fake
```

## Advanced Features

### Interactive Migrations

```yaml
provider: sh
interactive: true
command: |
  read -p "Enter your email: " email
  git config --global user.email "$email"
  echo "Git configured with $email"
```

### Force Symlink Replacement

```yaml
provider: symlink
links:
  - source: "~/dotfiles/.zshrc"
    target: "~/.zshrc"
    force: true  # Replaces existing file
```

### Multiple Providers in One Migration

```yaml
# Migration: Complete Setup
- provider: repo
  repos:
    - url: git@github.com:user/config.git
      path: "~/config"

- provider: symlink
  links:
    - source: "~/config/.vimrc"
      target: "~/.vimrc"

- provider: brew
  packages:
    - vim
    - tmux

- provider: sh
  command: echo "Setup complete!"
```

## Schema Validation

All providers use declarative schema validation with helpful error messages:

```yaml
# This will show: "Unknown properties: sourceee"
provider: symlink
links:
  - source: "/path/to/file"
    sourceee: "typo"  # Caught!
    target: "/dest"
```

**Validation features:**
- Required field checking
- Type validation (string, integer, boolean, array, hash)
- Unknown property detection
- Nested schema validation
- Clear, contextual error messages

## Testing

Run the comprehensive test suite:

```bash
cd dots
bundle exec rspec

# 82 examples covering:
# - ConfigSchema validation
# - All 5 providers
# - StateManager
# - MigrationManager
```

## Project Structure

```
dots/
├── bin/
│   └── dots                      # Main executable
├── lib/
│   ├── config_schema.rb          # Declarative validation DSL
│   ├── dots.rb                   # Main entry point
│   ├── cli.rb                    # Thor-based CLI
│   ├── migration_manager.rb      # Migration orchestration
│   ├── migration_template.yml    # Template for new migrations
│   ├── state_manager.rb          # State file handling
│   ├── provider.rb               # Base provider class
│   └── providers/
│       ├── sh.rb                 # Shell commands
│       ├── brew.rb               # Homebrew
│       ├── mas.rb                # Mac App Store
│       ├── repo.rb               # Git repositories
│       └── symlink.rb            # Symbolic links
├── spec/                         # RSpec tests (82 examples)
├── Gemfile
└── README.md

# In your dotfiles repo root:
migrations/                       # Your migration files
└── .state.yml                    # Local state (gitignored)
```

## Best Practices

1. **Small, focused migrations**: One logical task per migration
2. **Descriptive names**: Use `install-vim` not `update`
3. **Test before committing**: Use `--dry-run` first
4. **Commit migration files**: But not `.state.yml`
5. **Pull before applying**: Get latest migrations
6. **Use appropriate providers**: Don't use `sh` when `symlink` would work
7. **Add comments**: Use `# Migration: Description` at the top
8. **Make idempotent**: Safe to run multiple times
9. **Test migrations**: Use `dots exec` for testing

## Troubleshooting

**Migrations directory not found:**
```bash
dots create_migration init
```

**State file corrupted:**
Delete `migrations/.state.yml` and re-apply:
```bash
rm migrations/.state.yml
dots apply
```

**Migration modified warning:**
The migration file changed after being applied. Either:
- Revert the change
- Create a new migration
- Continue at your own risk

**Homebrew not found:**
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

**mas not found:**
```bash
brew install mas
```

**Permission errors:**
Make sure you have write access to the migrations directory and target paths.

**Unknown property errors:**
Check for typos in your YAML keys. The error message will tell you which properties are unknown.

## License

MIT
