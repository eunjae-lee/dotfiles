module Setup
  class CLI
  COMMANDS = %w[apply create validate].freeze
  
  def initialize(args)
    @command = args.shift
    @dry_run = args.include?('--dry-run')
    @config_only = args.include?('--config-only')
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
    elsif @config_only
      puts "CONFIG ONLY MODE - Only config.yml will be updated"
    end
    
    puts ""
    
    Migration.apply_all(dry_run: @dry_run, config_only: @config_only)
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
        apply [--dry-run|--config-only]    Apply pending migrations
        create <name>                       Create new migration
        validate                           Validate configuration
      
      EXAMPLES:
        ./setup apply                       # Apply all pending migrations
        ./setup apply --dry-run             # Preview what would be applied
        ./setup apply --config-only         # Update config.yml without running commands
        ./setup create add_docker           # Create new migration
        ./setup validate                    # Validate config and migrations
    USAGE
  end
  end
end