module Dots
  module Providers
    class SymlinkProvider < Provider
      def validate_config
        errors = []
        
        unless config['links'].is_a?(Array) && !config['links'].empty?
          errors << "SymlinkProvider requires 'links' array with at least one symlink"
        end

        if config['links'].is_a?(Array)
          config['links'].each_with_index do |link, index|
            unless link.is_a?(Hash)
              errors << "Link at index #{index} must be a hash"
              next
            end

            unless link['source'] && link['source'].is_a?(String) && !link['source'].strip.empty?
              errors << "Link at index #{index} missing or invalid 'source'"
            end

            unless link['target'] && link['target'].is_a?(String) && !link['target'].strip.empty?
              errors << "Link at index #{index} missing or invalid 'target'"
            end

            if link['force'] && !link['force'].is_a?(TrueClass) && !link['force'].is_a?(FalseClass)
              errors << "Link at index #{index} 'force' must be a boolean"
            end
          end
        end

        errors.empty? ? true : errors
      end

      def apply
        config['links'].each do |link|
          create_symlink(expand_path(link['source']), expand_path(link['target']), link['force'])
        end

        true
      end

      def describe
        count = config['links'].length
        "Create #{count} #{count == 1 ? 'symlink' : 'symlinks'}"
      end

      private

      def expand_path(path)
        File.expand_path(path.gsub('~', ENV['HOME']))
      end

      def create_symlink(source, target, force = false)
        unless File.exist?(source)
          raise ApplyError, "Source file does not exist: #{source}"
        end

        if File.symlink?(target)
          current_target = File.readlink(target)
          if current_target == source
            puts "Symlink already exists: #{target} -> #{source}"
            return
          else
            puts "Removing existing symlink: #{target} -> #{current_target}"
            File.unlink(target)
          end
        elsif File.exist?(target)
          if force
            if File.directory?(target)
              puts "Removing existing directory (force): #{target}"
              FileUtils.rm_rf(target)
            else
              puts "Removing existing file (force): #{target}"
              File.unlink(target)
            end
          else
            raise ApplyError, "Target already exists and is not a symlink: #{target}"
          end
        end

        target_dir = File.dirname(target)
        unless Dir.exist?(target_dir)
          puts "Creating parent directory: #{target_dir}"
          FileUtils.mkdir_p(target_dir)
        end

        puts "Creating symlink: #{target} -> #{source}"
        File.symlink(source, target)
      end
    end
  end
end
