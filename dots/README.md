# Dots - Dotfiles Migration Manager

A Ruby CLI tool for managing dotfiles migrations across multiple machines using a migration-based approach similar to database migrations.

## Features

- **Migration-based approach**: Track configuration changes over time with timestamped migration files
- **Multiple providers**: Support for shell commands, Homebrew, and Mac App Store
- **Idempotency**: Migrations are tracked and checksummed to prevent duplicate applications
- **Dry-run mode**: Preview changes before applying them
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

# Create your first migration (this creates the migrations/ directory)
dots migration setup-vim

# Edit the generated migration file
vim migrations/20250930_143022_setup-vim.yml

# Preview what will be applied
dots apply --dry-run

# Apply migrations
dots apply

# Check status
dots status
```

**Note:** The `migrations/` directory is created in your current working directory. Run `dots` commands from your dotfiles repository root.

## Usage

### Creating Migrations

```bash
dots migration MIGRATION_NAME
```

Creates a new migration file in `migrations/` with a timestamp prefix.

**Example:**
```bash
$ dots migration install-vim
Created: migrations/20250930_143022_install-vim.yml
```

### Migration File Format

Migration files are YAML files with a `provider` key and provider-specific configuration.

#### Shell Provider

Execute arbitrary shell commands:

```yaml
provider: sh
command: |
  ln -sf "$HOME/.dotfiles/vimrc" "$HOME/.vimrc"
  echo "Vim configured"
```

#### Homebrew Provider

Install Homebrew packages and casks:

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

**Features:**
- Automatically checks if packages are already installed (idempotent)
- Supports taps, packages, and casks
- Skips already installed items

#### Mac App Store Provider

Install Mac App Store applications using the `mas` CLI:

```yaml
provider: mas
apps:
  - name: "Xcode"
    id: 497799835
  - name: "1Password"
    id: 1333542190
```

**Requirements:**
- `mas` CLI must be installed: `brew install mas`
- You must be signed into the Mac App Store

### Applying Migrations

```bash
# Apply all pending migrations
dots apply

# Preview without applying (dry-run)
dots apply --dry-run
```

**Apply process:**
1. Finds all unapplied migrations
2. Validates each migration
3. Shows confirmation prompt
4. Applies migrations in order
5. Updates state file with checksums
6. Stops on first error

**Example output:**
```
Found 2 pending migration(s):
  - 20250930_143022_install-vim.yml: Install Homebrew 1 package(s)
  - 20250930_150145_configure-git.yml: Run shell command: git config --global user.name "John Doe"

Apply these migrations? (y/N) y

Applying: 20250930_143022_install-vim.yml
Installing package: vim
✓ Applied: 20250930_143022_install-vim.yml

Applying: 20250930_150145_configure-git.yml
✓ Applied: 20250930_150145_configure-git.yml

Successfully applied 2 migration(s)
```

### Checking Status

```bash
dots status
```

Shows count of applied and pending migrations:

```
Applied migrations: 5
Pending migrations: 2

Pending:
  - 20250930_163000_add-neovim.yml
  - 20250930_164500_install-fonts.yml
```

## State Management

- **State file**: `migrations/.state.yml` (in your working directory)
- **Automatically gitignored**: Added to `.gitignore` automatically
- **Machine-specific**: Each machine tracks its own applied migrations
- **Contains**: List of applied migrations with checksums
- **Format**:
  ```yaml
  - migration: 20250930_143022_install-vim.yml
    checksum: abc123def456...
  - migration: 20250930_150145_configure-git.yml
    checksum: def789ghi012...
  ```

### Checksum Validation

When applying migrations, checksums are compared to detect modifications:

- If a migration file has been modified since it was applied, you'll see a warning
- You can choose to continue or abort
- This prevents accidental re-application of changed migrations

## Workflow Example

### Initial Setup on Primary Machine

```bash
# Navigate to your dotfiles directory
cd ~/dotfiles

# Create first migration
dots migration install-homebrew
```

Edit `migrations/20250930_120000_install-homebrew.yml`:
```yaml
provider: brew
packages:
  - vim
  - tmux
  - git
```

```bash
# Apply
dots apply

# Commit (state file is auto-gitignored)
git add migrations/
git commit -m "Add Homebrew installation migration"
git push
```

### Setup on New Machine

```bash
# Clone your dotfiles
git clone <your-dotfiles-repo> ~/dotfiles
cd ~/dotfiles

# Install dots dependencies
cd dots
bundle install --path vendor/bundle
cd ..

# Apply all migrations
dots apply

# All your tools are now installed!
```

### Adding New Tools

```bash
# From your dotfiles directory
cd ~/dotfiles

# Create migration
dots migration add-neovim

# Edit migration file
vim migrations/20250930_160000_add-neovim.yml
```

```yaml
provider: brew
packages:
  - neovim
  - ripgrep
  - fd
```

```bash
# Apply locally
dots apply

# Commit and push
git add migrations/
git commit -m "Add Neovim and related tools"
git push

# On other machines
git pull
dots apply
```

## Provider Details

### Shell Provider (sh)

**Configuration:**
- `command` (required): Shell command(s) to execute

**Behavior:**
- Executes command using system shell
- Captures stdout and stderr
- Fails if exit code is non-zero
- Prints stdout after successful execution

**Use cases:**
- Creating symlinks
- Configuring git settings
- Running custom setup scripts
- File operations

### Homebrew Provider (brew)

**Configuration:**
- `taps` (optional): Array of Homebrew taps
- `packages` (optional): Array of formula names
- `casks` (optional): Array of cask names

**Behavior:**
- Checks if Homebrew is installed
- Skips already installed taps/packages/casks
- Installs in order: taps → packages → casks
- Idempotent: safe to run multiple times

**Use cases:**
- Installing CLI tools
- Installing GUI applications
- Adding third-party taps

### Mac App Store Provider (mas)

**Configuration:**
- `apps` (required): Array of app objects with `name` and `id`

**Behavior:**
- Requires `mas` CLI to be installed
- Checks if apps are already installed
- Uses App Store account credentials
- Skips already installed apps

**Use cases:**
- Installing App Store applications
- Automating app installations across machines

**Finding App IDs:**
```bash
# Search for an app
mas search Xcode

# List installed apps
mas list
```

## Error Handling

The tool handles various error scenarios:

- **Missing provider**: Error if provider is not recognized
- **Invalid YAML**: Clear error message for syntax errors
- **Validation errors**: Provider-specific validation failures
- **Apply errors**: Command execution failures with details
- **Corrupted state**: Detection and error reporting
- **Permission errors**: File system operation failures

All errors include descriptive messages to help diagnose issues.

## Best Practices

1. **Small, focused migrations**: Each migration should do one thing
2. **Descriptive names**: Use clear names like `install-vim` not `update`
3. **Test before committing**: Run `dots apply --dry-run` first
4. **Commit migration files**: But not the state file
5. **Pull before applying**: Get latest migrations from remote
6. **Document complex migrations**: Add comments in YAML files
7. **Use appropriate providers**: Don't use `sh` when `brew` would work

## Project Structure

```
dots/
├── bin/
│   └── dots                      # Main executable
├── lib/
│   ├── dots.rb                   # Main entry point
│   ├── cli.rb                    # Thor-based CLI
│   ├── migration_manager.rb      # Migration orchestration
│   ├── state_manager.rb          # State file handling
│   ├── provider.rb               # Base provider class
│   └── providers/
│       ├── sh.rb                 # Shell command provider
│       ├── brew.rb               # Homebrew provider
│       └── mas.rb                # Mac App Store provider
├── Gemfile
├── README.md
└── EXAMPLES.md

# In your dotfiles repo root:
migrations/                       # Your migration files (in working dir)
└── .state.yml                    # Local state (gitignored)
```

## Extending with Custom Providers

To add a new provider:

1. Create a new file in `lib/providers/`
2. Inherit from `Dots::Provider`
3. Implement three methods:
   - `validate_config`: Validate the configuration hash
   - `apply`: Execute the migration
   - `describe`: Return a human-readable description
4. Register in `lib/provider.rb` in the `self.for` method

**Example:**
```ruby
module Dots
  module Providers
    class CustomProvider < Provider
      def validate_config
        unless config['required_key']
          raise ValidationError, "CustomProvider requires 'required_key'"
        end
        true
      end

      def apply
        # Your implementation
        true
      end

      def describe
        "Custom provider: #{config['required_key']}"
      end
    end
  end
end
```

## Troubleshooting

**Migrations directory not found:**
```bash
dots migration init
```

**State file corrupted:**
Delete `migrations/.state.yml` and re-apply all migrations.

**Migration modified warning:**
This means a migration file changed after it was applied. Either:
- Revert the change
- Create a new migration for the changes
- Continue at your own risk

**Homebrew not found:**
Install Homebrew from https://brew.sh

**mas not found:**
```bash
brew install mas
```

## License

MIT