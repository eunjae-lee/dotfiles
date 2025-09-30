module Dots
  class StateManager
    def initialize
      ensure_migrations_dir
      ensure_gitignore
    end

    def migrations_dir
      @migrations_dir ||= File.join(Dir.pwd, 'migrations')
    end

    def state_file
      @state_file ||= File.join(migrations_dir, '.state.yml')
    end

    def applied_migrations
      return [] unless File.exist?(state_file)

      begin
        state = YAML.load_file(state_file) || []
        state.is_a?(Array) ? state.map { |entry| normalize_entry(entry) } : []
      rescue Psych::SyntaxError => e
        raise StateError, "Corrupted state file: #{e.message}"
      end
    end

    def add_migration(filename, checksum)
      migrations = applied_migrations
      migrations << { 'migration' => filename, 'checksum' => checksum }
      save_state(migrations)
    end

    def find_checksum(filename)
      entry = applied_migrations.find { |m| m['migration'] == filename }
      entry ? entry['checksum'] : nil
    end

    def all_migration_files
      return [] unless Dir.exist?(migrations_dir)

      Dir.glob(File.join(migrations_dir, '*.yml'))
         .reject { |f| File.basename(f) == '.state.yml' }
         .map { |f| File.basename(f) }
         .sort
    end

    def pending_migrations
      applied = applied_migrations.map { |m| m['migration'] }
      all_migration_files - applied
    end

    def migration_path(filename)
      File.join(migrations_dir, filename)
    end

    def calculate_checksum(filepath)
      Digest::SHA256.file(filepath).hexdigest
    end

    private

    def normalize_entry(entry)
      if entry.is_a?(String)
        { 'migration' => entry, 'checksum' => nil }
      else
        entry
      end
    end

    def ensure_migrations_dir
      FileUtils.mkdir_p(migrations_dir) unless Dir.exist?(migrations_dir)
    end

    def ensure_gitignore
      gitignore_path = '.gitignore'
      gitignore_entry = 'migrations/.state.yml'

      if File.exist?(gitignore_path)
        content = File.read(gitignore_path)
        lines = content.lines.map(&:strip)
        unless lines.include?(gitignore_entry)
          File.open(gitignore_path, 'a') { |f| f.puts gitignore_entry }
        end
      else
        File.write(gitignore_path, "#{gitignore_entry}\n")
      end
    end

    def save_state(migrations)
      File.write(state_file, migrations.to_yaml)
    end
  end
end