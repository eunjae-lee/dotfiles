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

      template_path = File.expand_path('../migration_template.yml', __FILE__)
      template_content = File.read(template_path)
      
      content = template_content.gsub('__NAME__', name)

      File.write(filepath, content)
      filename
    end

    def load_migration(filename)
      filepath = state_manager.migration_path(filename)
      
      begin
        content = YAML.load_file(filepath)
        raise ValidationError, "Migration file is empty: #{filename}" if content.nil?

        if content.is_a?(Array)
          content.each_with_index do |config, index|
            raise ValidationError, "Migration at index #{index} must be a hash: #{filename}" unless config.is_a?(Hash)
            raise ValidationError, "Migration at index #{index} missing 'provider' key: #{filename}" unless config['provider']
          end
          content
        elsif content.is_a?(Hash)
          raise ValidationError, "Migration missing 'provider' key: #{filename}" unless content['provider']
          [content]
        else
          raise ValidationError, "Migration must be a hash or array of hashes: #{filename}"
        end
      rescue Psych::SyntaxError => e
        raise ValidationError, "Invalid YAML in #{filename}: #{e.message}"
      end
    end

    def validate_migration(filename)
      configs = load_migration(filename)
      
      migrations = configs.map.with_index do |config, index|
        provider = Provider.for(config['provider'], config)
        provider.validate_config
        { filename: filename, index: index, config: config, provider: provider }
      end

      migrations
    end

    def apply_migration(filename, dry_run: false)
      migrations = validate_migration(filename)
      filepath = state_manager.migration_path(filename)
      current_checksum = state_manager.calculate_checksum(filepath)
      stored_checksum = state_manager.find_checksum(filename)

      if stored_checksum && stored_checksum != current_checksum
        raise ValidationError, "Migration '#{filename}' has been modified since it was applied"
      end

      if dry_run
        descriptions = migrations.map { |m| m[:provider].describe }
        return descriptions.length == 1 ? descriptions.first : descriptions
      end

      migrations.each do |migration|
        migration[:provider].apply
      end
      
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