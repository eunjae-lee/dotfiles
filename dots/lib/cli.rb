require 'thor'
require 'tty-prompt'

module Dots
  class CLI < Thor
    def self.exit_on_failure?
      true
    end

    class << self
      def handle_argument_error(task, error, args, arity)
        if args.include?('--help') || args.include?('-h') || (args.empty? && error.message.include?('no arguments'))
          new.invoke(:help, [task.name])
        else
          super
        end
      end

      def handle_no_command_error(command, has_namespace = $thor_runner)
        if command == '--help' || command == '-h'
          help
        else
          super
        end
      end
    end

    desc "create_migration NAME", "Create a new migration file"
    long_desc <<-LONGDESC
      Create a new migration file with the given NAME.

      The migration file will be created in the migrations/ directory with a timestamp prefix.

      Example:
      $ dots create_migration install-vim

      This will create a file like: migrations/20240101120000_install-vim.yml
    LONGDESC
    def create_migration(name)
      if name == '--help' || name == '-h'
        invoke(:help, ['create_migration'])
        return
      end

      manager = MigrationManager.new
      filename = manager.create_migration(name)
      puts "Created: migrations/#{filename}"
    rescue Dots::Error => e
      puts "Error: #{e.message}"
      exit 1
    end

    desc "apply", "Apply pending migrations"
    long_desc <<-LONGDESC
      Apply all pending migrations.

      This command will show you the pending migrations and ask for confirmation before applying them.
      Use the --dry-run flag to preview what would be applied without making any changes.

      Options:
      -d, --dry-run  Preview migrations without applying them
      -y, --yes      Skip confirmation prompt and apply all migrations
      -f, --fake     Mark migrations as applied without executing them

      Example:
      $ dots apply
      $ dots apply --dry-run
      $ dots apply --yes
      $ dots apply --fake
    LONGDESC
    option :dry_run, type: :boolean, aliases: '-d', desc: 'Preview migrations without applying them'
    option :yes, type: :boolean, aliases: '-y', desc: 'Skip confirmation prompt'
    option :fake, type: :boolean, aliases: '-f', desc: 'Mark as applied without executing'
    def apply
      manager = MigrationManager.new
      pending = manager.pending_migrations

      if pending.empty?
        puts "No pending migrations"
        return
      end

      puts "Found #{pending.length} pending migration(s):"
      
      descriptions = {}
      pending.each do |filename|
        begin
          migrations = manager.validate_migration(filename)
          if migrations.length == 1
            description = migrations.first[:provider].describe
            descriptions[filename] = description
            puts "  - #{filename}: #{description}"
          else
            descriptions[filename] = migrations.map { |m| m[:provider].describe }
            puts "  - #{filename}: #{migrations.length} migration(s)"
            migrations.each_with_index do |m, i|
              puts "      #{i + 1}. #{m[:provider].describe}"
            end
          end
        rescue Dots::Error => e
          puts "  - #{filename}: ERROR - #{e.message}"
          exit 1
        end
      end

      if options[:dry_run]
        puts "\nNo migrations applied (dry-run mode)"
        return
      end

      if options[:fake]
        puts "\nMarking migrations as applied without executing (fake mode)"
        pending.each do |filename|
          migration_name = manager.extract_migration_name(filename)
          filepath = manager.state_manager.migration_path(filename)
          checksum = manager.state_manager.calculate_checksum(filepath)
          manager.state_manager.add_migration(filename, checksum)
          puts "✓ Marked as applied: #{migration_name}"
        end
        puts "\nSuccessfully marked #{pending.length} migration(s) as applied"
        return
      end

      unless options[:yes]
        prompt = TTY::Prompt.new
        return unless prompt.yes?("\nApply these migrations?", default: false)
      end

      applied_count = 0
      pending.each do |filename|
        migration_name = manager.extract_migration_name(filename)
        puts "\nApplying the migration: #{migration_name}"
        
        begin
          manager.apply_migration(filename)
          puts "✓ Applied: #{migration_name}"
          applied_count += 1
        rescue Dots::ValidationError => e
          puts "⚠ Warning: #{e.message}"
          break unless prompt.yes?("Continue anyway?", default: false)
          
          begin
            filepath = manager.state_manager.migration_path(filename)
            migrations = manager.validate_migration(filename)
            migrations.each do |migration|
              migration[:provider].apply
            end
            checksum = manager.state_manager.calculate_checksum(filepath)
            manager.state_manager.add_migration(filename, checksum)
            puts "✓ Applied: #{migration_name}"
            applied_count += 1
          rescue Dots::Error => e
            puts "✗ Failed: #{e.message}"
            break
          end
        rescue Dots::Error => e
          puts "✗ Failed: #{e.message}"
          break
        end
      end

      puts "\nSuccessfully applied #{applied_count} migration(s)"
    rescue Dots::Error => e
      puts "Error: #{e.message}"
      exit 1
    end

    desc "exec FILE", "Execute a single migration file without tracking state"
    long_desc <<-LONGDESC
      Execute a single migration file without adding it to the state file.

      This is useful for testing migrations during development without affecting
      the migration state.

      Example:
      $ dots exec migrations/20240101_test.yml
      $ dots exec /path/to/test-migration.yml
    LONGDESC
    def exec(filepath)
      if filepath == '--help' || filepath == '-h'
        invoke(:help, ['exec'])
        return
      end

      filepath = File.expand_path(filepath)
      
      unless File.exist?(filepath)
        puts "Error: File not found: #{filepath}"
        exit 1
      end

      filename = File.basename(filepath)
      migration_name = extract_name_from_file(filepath)

      puts "Running migration: #{migration_name}"

      begin
        content = YAML.load_file(filepath)
        raise Dots::ValidationError, "Migration file is empty: #{filename}" if content.nil?

        configs = if content.is_a?(Array)
          content
        elsif content.is_a?(Hash)
          [content]
        else
          raise Dots::ValidationError, "Migration must be a hash or array of hashes"
        end

        configs.each_with_index do |config, index|
          raise Dots::ValidationError, "Migration at index #{index} must be a hash" unless config.is_a?(Hash)
          raise Dots::ValidationError, "Migration at index #{index} missing 'provider' key" unless config['provider']
          
          provider = Provider.for(config['provider'], config)
          validation_result = provider.validate_config
          
          unless validation_result == true
            errors = Array(validation_result).join("\n  - ")
            raise Dots::ValidationError, "Validation failed:\n  - #{errors}"
          end
          
          provider.apply
        end
        
        puts "✓ Completed: #{migration_name}"
      rescue Psych::SyntaxError => e
        puts "✗ Failed: Invalid YAML: #{e.message}"
        exit 1
      rescue Dots::Error => e
        puts "✗ Failed: #{e.message}"
        exit 1
      end
    rescue Dots::Error => e
      puts "Error: #{e.message}"
      exit 1
    end

    private

    def extract_name_from_file(filepath)
      first_line = File.open(filepath, &:readline).strip rescue nil
      
      if first_line && first_line.match(/^#\s*Migration:\s*(.+)/)
        $1.strip
      else
        filename = File.basename(filepath)
        filename.sub(/^\d+_\d+_/, '').sub(/\.yml$/, '').gsub('-', ' ')
      end
    end

    public

    desc "status", "Show migration status"
    def status
      manager = MigrationManager.new
      applied = manager.applied_count
      pending = manager.pending_migrations

      puts "Applied migrations: #{applied}"
      puts "Pending migrations: #{pending.length}"

      if pending.any?
        puts "\nPending:"
        pending.each do |filename|
          puts "  - #{filename}"
        end
      end
    rescue Dots::Error => e
      puts "Error: #{e.message}"
      exit 1
    end
  end
end