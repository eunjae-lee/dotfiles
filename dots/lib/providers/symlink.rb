module Dots
  module Providers
    class SymlinkProvider < Provider
      def self.link_schema
        @link_schema ||= begin
          schema = ConfigSchema.new
          schema.field :source, type: :string, required: true
          schema.field :target, type: :string, required: true
          schema.field :force, type: :boolean
          schema
        end
      end

      def self.schema
        @schema ||= begin
          schema = ConfigSchema.new
          schema.field :links, type: :array, required: true, array_item_schema: link_schema
          schema
        end
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
