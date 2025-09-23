module Setup
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
  
  def self.apply_all(dry_run: false, config_only: false)
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
      
      if config_only
        puts "  → Updating config only (skipping commands)"
      else
        migration.apply(dry_run: dry_run)
      end
      
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
    # First execute provider-based config changes
    execute_config_changes(dry_run)
    
    # Then execute any custom commands
    execute_custom_commands(dry_run)
  end
  
  private
  
  def execute_config_changes(dry_run)
    return if @config_data.empty?
    
    puts "  → Executing configuration changes"
    
    @config_data.each do |section, config|
      provider_class = Config::PROVIDERS[section] || DefaultProvider
      provider = provider_class.new
      
      if provider.respond_to?(:execute)
        puts "    Processing #{section} configuration..."
        provider.execute(config, dry_run: dry_run)
      else
        puts "    Skipping #{section} (no execution implemented)"
      end
    end
  end
  
  def execute_custom_commands(dry_run)
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
end