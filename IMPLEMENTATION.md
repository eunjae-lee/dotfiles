# Minimal Migration System - Implementation Plan

## Overview

Transform the current complex setup system into a minimal, migration-focused system with provider-based schema validation and config merging. The goal is to maintain a single source of truth in `config.yml` that gets updated as migrations are applied.

## Core Principles

1. **Single Source of Truth**: `config.yml` contains current state + applied migrations list
2. **Migration-Driven**: All changes happen through migrations
3. **Provider-Based**: Each config section has domain-specific merge logic and validation
4. **Minimal Complexity**: ~350 lines total vs current ~2000+ lines
5. **Shell-Command Based**: Migrations contain direct shell commands, no Ruby abstractions

## Architecture

### File Structure (Minimal)
```
setup                          # Main CLI script  
config.yml                     # Single source of truth
migrations/                    # Migration files
  001_initial_homebrew.yml
  002_add_docker.yml
lib/
  setup.rb                     # Main module
  cli.rb                       # 3 commands only
  config.rb                    # Config parser + provider-based merger
  migration.rb                 # Migration engine
  schema.rb                    # Simple schema validation
  providers/                   # Provider classes
    base.rb                    # Base provider
    homebrew.rb                # Homebrew provider
    default.rb                 # Default provider
test/
  test_*.rb                    # Core tests
```

### Commands (Just 3)
```bash
./setup apply [--dry-run]     # Apply pending migrations + update config.yml
./setup create <name>         # Create new migration template  
./setup validate             # Validate config.yml + migrations
```

## Implementation Details

### 1. Migration Format

```yaml
# migrations/001_homebrew.yml
name: "Setup Homebrew"
description: "Install Homebrew and basic packages"

# What gets merged into config.yml when applied
config:
  homebrew:
    install: true
    packages:
      - git  
      - vim
    casks:
      - slack

# Shell commands to execute
up:
  - name: "Install Homebrew"
    command: '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    check: "which brew"
    
  - name: "Install packages"  
    command: "brew install git vim"
```

**Key Points:**
- No `down` section (no rollback support for now)
- `config` section gets merged into main config.yml
- `up` contains idempotent shell commands
- Optional `check` commands for verification

### 2. Config Update Flow

**Before any migrations:**
```yaml
# config.yml
_applied_migrations: []
```

**After applying `001_homebrew.yml`:**
```yaml  
# config.yml
_applied_migrations:
  - 001_homebrew

homebrew:
  install: true  
  packages:
    - git
    - vim
  casks:
    - slack
```

**After applying `002_docker.yml`:**
```yaml
# config.yml  
_applied_migrations:
  - 001_homebrew
  - 002_docker

homebrew:
  install: true
  packages:
    - git
    - vim  
    - docker  # Added by migration (union merge)
  casks:
    - slack
```

### 3. Provider-Based Architecture

#### Simple Schema Validation (Option 1)

```ruby
# lib/schema.rb
class SimpleSchema
  def self.validate(data, schema)
    schema.each do |key, rules|
      value = data[key]
      
      # Check required
      if rules[:required] && !data.key?(key)
        raise "Missing required key: #{key}"
      end
      
      next unless value # Skip validation if nil/missing
      
      # Check type
      case rules[:type]
      when 'string'
        raise "#{key} must be string" unless value.is_a?(String)
      when 'array'
        raise "#{key} must be array" unless value.is_a?(Array)
      when 'boolean'
        raise "#{key} must be boolean" unless [true, false].include?(value)
      when 'hash'
        raise "#{key} must be hash" unless value.is_a?(Hash)
      end
      
      # Check array items
      if rules[:items] && value.is_a?(Array)
        value.each_with_index do |item, index|
          case rules[:items]
          when 'string'
            raise "#{key}[#{index}] must be string" unless item.is_a?(String)
          when 'hash'
            # Could validate nested hash structure
          end
        end
      end
    end
  end
end
```

#### Base Provider Class

```ruby
# lib/providers/base.rb
class BaseProvider
  def validate(config)
    # Override in subclasses
    true
  end
  
  def merge(existing, new_config)
    # Default behavior: simple merge
    existing.merge(new_config)
  end
  
  protected
  
  def union_arrays(existing_array, new_array)
    (existing_array + new_array).uniq
  end
  
  def deep_merge_hashes(existing_hash, new_hash)
    existing_hash.merge(new_hash) do |key, old_val, new_val|
      if old_val.is_a?(Hash) && new_val.is_a?(Hash)
        deep_merge_hashes(old_val, new_val)
      else
        new_val
      end
    end
  end
end
```

#### Homebrew Provider

```ruby
# lib/providers/homebrew.rb
class HomebrewProvider < BaseProvider
  SCHEMA = {
    'install' => { type: 'boolean', required: false },
    'update' => { type: 'boolean', required: false },
    'packages' => { type: 'array', items: 'string', required: false },
    'casks' => { type: 'array', items: 'string', required: false },
    'taps' => { type: 'array', items: 'string', required: false }
  }
  
  def validate(config)
    SimpleSchema.validate(config, SCHEMA)
  end
  
  def merge(existing, new_config)
    result = existing.dup
    
    # Union arrays for packages, casks, taps
    %w[packages casks taps].each do |key|
      if new_config[key]
        result[key] = union_arrays(existing[key] || [], new_config[key])
      end
    end
    
    # Simple merge for boolean flags
    %w[install update].each do |key|
      result[key] = new_config[key] if new_config.key?(key)
    end
    
    result
  end
end
```

#### Default Provider

```ruby
# lib/providers/default.rb
class DefaultProvider < BaseProvider
  def validate(config)
    # Basic validation: ensure it's a hash
    raise "Config must be a hash" unless config.is_a?(Hash)
    true
  end
  
  def merge(existing, new_config)
    # Default merge strategy
    case
    when existing.is_a?(Array) && new_config.is_a?(Array)
      union_arrays(existing, new_config)
    when existing.is_a?(Hash) && new_config.is_a?(Hash)
      deep_merge_hashes(existing, new_config)
    when existing == new_config
      new_config  # Same value, no conflict
    else
      raise "Conflict: Can't merge #{existing.class}(#{existing}) with #{new_config.class}(#{new_config})"
    end
  end
end
```

### 4. Core Implementation

#### CLI Interface

```ruby
# lib/cli.rb
class CLI
  COMMANDS = %w[apply create validate].freeze
  
  def initialize(args)
    @command = args.shift
    @dry_run = args.include?('--dry-run')
    @migration_name = args.find { |arg| !arg.start_with?('--') }
    @args = args
  end
  
  def run
    case @command
    when 'apply'
      apply_migrations
    when 'create'
      create_migration
    when 'validate'
      validate_config
    else
      show_usage
    end
  end
  
  private
  
  def apply_migrations
    puts "Setup - Apply Migrations"
    puts "======================="
    
    if @dry_run
      puts "DRY RUN MODE - No changes will be made"
    end
    
    puts ""
    
    Migration.apply_all(dry_run: @dry_run)
  end
  
  def create_migration
    unless @migration_name
      puts "Error: Migration name required"
      puts "Usage: ./setup create <name>"
      exit 1
    end
    
    Migration.create(@migration_name)
  end
  
  def validate_config
    puts "Setup - Validate Configuration"
    puts "=============================="
    puts ""
    
    config = Config.new
    config.validate!
    
    puts "✓ Configuration is valid"
    puts "✓ All migrations are valid"
  end
  
  def show_usage
    puts <<~USAGE
      Setup - Minimal Migration System
      
      USAGE:
        ./setup <command> [options]
      
      COMMANDS:
        apply [--dry-run]    Apply pending migrations
        create <name>        Create new migration
        validate            Validate configuration
      
      EXAMPLES:
        ./setup apply                    # Apply all pending migrations
        ./setup apply --dry-run          # Preview what would be applied
        ./setup create add_docker        # Create new migration
        ./setup validate                # Validate config and migrations
    USAGE
  end
end
```

#### Config Management

```ruby
# lib/config.rb
require_relative 'providers/homebrew'
require_relative 'providers/default'

class Config
  PROVIDERS = {
    'homebrew' => HomebrewProvider,
    'vscode' => DefaultProvider,  # Add VSCodeProvider later
    'git' => DefaultProvider,     # Add GitProvider later
    'dotfiles' => DefaultProvider # Add DotfilesProvider later
  }.freeze
  
  def initialize
    @data = load_config
  end
  
  def applied_migrations
    @data['_applied_migrations'] || []
  end
  
  def pending_migrations
    all_migrations - applied_migrations
  end
  
  def validate!
    @data.each do |section, config|
      next if section == '_applied_migrations'
      validate_section(section, config)
    end
  end
  
  def merge_migration!(migration_name, migration_config)
    # Validate each section before merging
    migration_config.each do |section, config|
      validate_section(section, config)
    end
    
    # Merge with provider-specific logic
    migration_config.each do |section, new_config|
      if @data[section]
        @data[section] = merge_section(section, @data[section], new_config)
      else
        @data[section] = new_config
      end
    end
    
    # Track applied migration
    @data['_applied_migrations'] ||= []
    @data['_applied_migrations'] << migration_name
    
    save_config!
  end
  
  private
  
  def load_config
    if File.exist?('config.yml')
      YAML.load_file('config.yml') || {}
    else
      { '_applied_migrations' => [] }
    end
  end
  
  def save_config!
    File.write('config.yml', @data.to_yaml)
  end
  
  def all_migrations
    Dir.glob('migrations/*.yml').map do |file|
      File.basename(file, '.yml')
    end.sort
  end
  
  def validate_section(section, config)
    provider_class = PROVIDERS[section] || DefaultProvider
    provider = provider_class.new
    provider.validate(config)
  end
  
  def merge_section(section, existing, new_config)
    provider_class = PROVIDERS[section] || DefaultProvider
    provider = provider_class.new
    provider.merge(existing, new_config)
  end
end
```

#### Migration Engine

```ruby
# lib/migration.rb
class Migration
  attr_reader :name, :description, :config_data, :commands
  
  def initialize(file_path)
    @file_path = file_path
    @data = YAML.load_file(file_path)
    @name = File.basename(file_path, '.yml')
    @description = @data['description']
    @config_data = @data['config'] || {}
    @commands = @data['up'] || []
  end
  
  def self.apply_all(dry_run: false)
    config = Config.new
    pending = config.pending_migrations
    
    if pending.empty?
      puts "No pending migrations"
      return
    end
    
    puts "Applying #{pending.size} migration(s)..."
    puts ""
    
    pending.each do |migration_name|
      migration_file = "migrations/#{migration_name}.yml"
      migration = new(migration_file)
      
      puts "Applying: #{migration.name}"
      puts "  #{migration.description}" if migration.description
      
      migration.apply(dry_run: dry_run)
      
      unless dry_run
        config.merge_migration!(migration_name, migration.config_data)
      end
      
      puts "  ✓ Completed"
      puts ""
    end
    
    puts "✓ All migrations applied successfully!"
  end
  
  def self.create(name)
    timestamp = Time.now.strftime('%Y%m%d%H%M%S')
    filename = "#{timestamp}_#{name.gsub(/[^a-zA-Z0-9_]/, '_')}"
    filepath = "migrations/#{filename}.yml"
    
    Dir.mkdir('migrations') unless Dir.exist?('migrations')
    
    template = <<~YAML
      name: "#{name.gsub('_', ' ').split.map(&:capitalize).join(' ')}"
      description: ""
      
      # Configuration that gets merged into config.yml
      config:
        # Example:
        # homebrew:
        #   packages:
        #     - docker
      
      # Commands to execute
      up:
        - name: "TODO: Add command description"
          command: "echo 'TODO: Add your command here'"
          # check: "echo 'Optional: verification command'"
    YAML
    
    File.write(filepath, template)
    puts "Created migration: #{filepath}"
    puts ""
    puts "Edit the migration file and then run:"
    puts "  ./setup apply --dry-run  # Preview"
    puts "  ./setup apply            # Execute"
  end
  
  def apply(dry_run: false)
    @commands.each do |step|
      puts "  → #{step['name']}"
      
      if dry_run
        puts "    $ #{step['command']}"
        puts "      (dry-run - would execute)"
      else
        success = system(step['command'])
        unless success
          raise "Command failed: #{step['command']}"
        end
        
        # Run optional check command
        if step['check']
          check_success = system(step['check'])
          puts "    ✓ Verified" if check_success
        end
      end
    end
  end
end
```

#### Main Setup Script

```ruby
#!/usr/bin/env ruby
# setup script

require_relative 'lib/setup'

begin
  Setup::CLI.new(ARGV).run
rescue Setup::Error => e
  puts "Error: #{e.message}"
  exit 1
rescue Interrupt
  puts "\nInterrupted"
  exit 130
end
```

```ruby
# lib/setup.rb
require 'yaml'
require 'fileutils'

module Setup
  class Error < StandardError; end
  class ConfigError < Error; end
  class MigrationError < Error; end
  
  autoload :CLI, File.expand_path('cli', __dir__)
  autoload :Config, File.expand_path('config', __dir__)
  autoload :Migration, File.expand_path('migration', __dir__)
  autoload :SimpleSchema, File.expand_path('schema', __dir__)
end

require_relative 'cli'
require_relative 'config'
require_relative 'migration'
require_relative 'schema'
```

## Implementation Strategy

### Phase 1: Core Migration Engine (~200 lines)
1. Basic CLI with 3 commands
2. Simple config loading/saving
3. Migration creation and application
4. Shell command execution with dry-run

### Phase 2: Provider System (~100 lines)
5. Base provider class
6. Simple schema validation
7. Homebrew provider (most important)
8. Default provider fallback

### Phase 3: Polish (~50 lines)
9. Better error handling
10. Improved output formatting
11. Basic tests

## Migration from Current System

### Step 1: Extract Current State
Run a script to extract current `config.yml` into an initial migration:

```yaml
# migrations/001_current_state.yml
name: "Current System State"
description: "Migrate from bash scripts to migration system"

config:
  # Copy current config.yml contents here
  homebrew:
    packages: [git, vim, ...]
  # ... etc

up:
  - name: "System already configured"
    command: "echo 'Migration from existing setup complete'"
```

### Step 2: Mark as Applied
```yaml
# new config.yml
_applied_migrations:
  - 001_current_state

# ... rest of current config
```

### Step 3: Future Changes
All future changes use the new migration system.

## Shell Command Guidelines

### Use Idempotent Commands
```yaml
up:
  - name: "Install Git"
    command: "brew list git || brew install git"  # Only install if not present
    
  - name: "Create directory"
    command: "mkdir -p ~/workspace"  # -p flag makes it idempotent
    
  - name: "Clone repo"
    command: "cd ~/workspace && (test -d dotfiles || git clone git@github.com:user/dotfiles.git)"
```

### Include Verification
```yaml
up:
  - name: "Install Homebrew"
    command: '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    check: "/usr/local/bin/brew --version || /opt/homebrew/bin/brew --version"
```

### Use Full Paths for Critical Tools
```yaml
up:
  - name: "Install Homebrew"
    command: '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
```

## Testing Strategy

### Unit Tests
- Config loading/saving
- Provider validation and merging
- Migration parsing and application
- Schema validation

### Integration Tests  
- End-to-end migration application
- Dry-run functionality
- Error scenarios

### Example Test Structure
```ruby
# test/test_homebrew_provider.rb
class TestHomebrewProvider < Minitest::Test
  def test_merge_packages
    existing = { 'packages' => ['git', 'vim'] }
    new_config = { 'packages' => ['docker', 'git'] }
    
    provider = HomebrewProvider.new
    result = provider.merge(existing, new_config)
    
    assert_equal ['git', 'vim', 'docker'], result['packages']
  end
end
```

## Benefits of This Architecture

1. **Single Source of Truth**: config.yml always shows current state
2. **Minimal Complexity**: ~350 lines vs 2000+ lines
3. **Provider Expertise**: Each domain has custom validation and merge logic
4. **Git-Friendly**: Easy to see config changes in diffs
5. **Transparent**: Raw shell commands, no hidden abstractions
6. **Extensible**: Easy to add new providers
7. **Safe**: Dry-run support and validation before execution

## Usage Examples

### Initial Setup
```bash
./setup create initial_homebrew
# Edit migrations/001_initial_homebrew.yml
./setup apply --dry-run        # Preview
./setup apply                  # Execute + update config.yml
```

### Add Docker
```bash
./setup create add_docker
# Edit migrations/002_add_docker.yml  
./setup apply --dry-run        # Preview
./setup apply                  # Execute + merge into config.yml
```

### Check Current State
```bash
cat config.yml                 # See current config + applied migrations
./setup validate               # Validate everything
```

This minimal system provides exactly what you need: migration-driven configuration management with provider-based domain expertise, all while maintaining a single source of truth in config.yml.
