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

    desc "migration NAME", "Create a new migration file"
    long_desc <<-LONGDESC
      Create a new migration file with the given NAME.

      The migration file will be created in the migrations/ directory with a timestamp prefix.

      Example:
      $ dots migration install-vim

      This will create a file like: migrations/20240101120000_install-vim.yml
    LONGDESC
    def migration(name)
      if name == '--help' || name == '-h'
        invoke(:help, ['migration'])
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

      Example:
      $ dots apply
      $ dots apply --dry-run
    LONGDESC
    option :dry_run, type: :boolean, aliases: '-d', desc: 'Preview migrations without applying them'
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

      prompt = TTY::Prompt.new
      return unless prompt.yes?("\nApply these migrations?", default: false)

      applied_count = 0
      pending.each do |filename|
        puts "\nApplying: #{filename}"
        
        begin
          manager.apply_migration(filename)
          puts "✓ Applied: #{filename}"
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
            puts "✓ Applied: #{filename}"
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