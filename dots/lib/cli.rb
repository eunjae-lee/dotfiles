require 'thor'
require 'tty-prompt'

module Dots
  class CLI < Thor
    def self.exit_on_failure?
      true
    end

    desc "migration NAME", "Create a new migration file"
    def migration(name)
      manager = MigrationManager.new
      filename = manager.create_migration(name)
      puts "Created: migrations/#{filename}"
    rescue Dots::Error => e
      puts "Error: #{e.message}"
      exit 1
    end

    desc "apply", "Apply pending migrations"
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