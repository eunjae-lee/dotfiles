module Dots
  class MigrationManager
    attr_reader :state_manager

    def initialize(state_manager = StateManager.new)
      @state_manager = state_manager
    end

    def create_migration(name)
      timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
      filename = "#{timestamp}_#{name}.yml"
      filepath = state_manager.migration_path(filename)

      template = <<~YAML
        provider: sh
        command: |
          # Your migration code here
          echo "Migration: #{name}"
      YAML

      File.write(filepath, template)
      filename
    end

    def load_migration(filename)
      filepath = state_manager.migration_path(filename)
      
      begin
        config = YAML.load_file(filepath)
        raise ValidationError, "Migration file is empty: #{filename}" if config.nil?
        raise ValidationError, "Migration must be a hash: #{filename}" unless config.is_a?(Hash)
        raise ValidationError, "Migration missing 'provider' key: #{filename}" unless config['provider']

        config
      rescue Psych::SyntaxError => e
        raise ValidationError, "Invalid YAML in #{filename}: #{e.message}"
      end
    end

    def validate_migration(filename)
      config = load_migration(filename)
      provider = Provider.for(config['provider'], config)
      provider.validate_config
      { filename: filename, config: config, provider: provider }
    end

    def apply_migration(filename, dry_run: false)
      migration = validate_migration(filename)
      filepath = state_manager.migration_path(filename)
      current_checksum = state_manager.calculate_checksum(filepath)
      stored_checksum = state_manager.find_checksum(filename)

      if stored_checksum && stored_checksum != current_checksum
        raise ValidationError, "Migration '#{filename}' has been modified since it was applied"
      end

      return migration[:provider].describe if dry_run

      migration[:provider].apply
      state_manager.add_migration(filename, current_checksum)
      true
    end

    def pending_migrations
      state_manager.pending_migrations
    end

    def applied_count
      state_manager.applied_migrations.length
    end
  end
end