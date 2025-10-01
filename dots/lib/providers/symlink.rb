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
          end
        end

        errors.empty? ? true : errors
      end

      def apply
        config['links'].each do |link|
          create_symlink(expand_path(link['source']), expand_path(link['target']))
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

      def create_symlink(source, target)
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
          raise ApplyError, "Target already exists and is not a symlink: #{target}"
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
