module Dots
  module Providers
    class RepoProvider < Provider
      def validate_config
        errors = []
        
        unless config['repos'].is_a?(Array) && !config['repos'].empty?
          errors << "RepoProvider requires 'repos' array with at least one repository"
        end

        if config['repos'].is_a?(Array)
          config['repos'].each_with_index do |repo, index|
            unless repo.is_a?(Hash)
              errors << "Repository at index #{index} must be a hash"
              next
            end

            unless repo['url'] && repo['url'].is_a?(String) && !repo['url'].strip.empty?
              errors << "Repository at index #{index} missing or invalid 'url'"
            end

            unless repo['path'] && repo['path'].is_a?(String) && !repo['path'].strip.empty?
              errors << "Repository at index #{index} missing or invalid 'path'"
            end
          end
        end

        errors.empty? ? true : errors
      end

      def apply
        config['repos'].each do |repo|
          clone_repo(repo['url'], expand_path(repo['path']))
        end

        true
      end

      def describe
        count = config['repos'].length
        "Clone #{count} git #{count == 1 ? 'repository' : 'repositories'}"
      end

      private

      def expand_path(path)
        File.expand_path(path.gsub('~', ENV['HOME']))
      end

      def clone_repo(url, path)
        if Dir.exist?(File.join(path, '.git'))
          puts "Repository already exists: #{path}"
          return
        end

        parent_dir = File.dirname(path)
        unless Dir.exist?(parent_dir)
          puts "Creating parent directory: #{parent_dir}"
          FileUtils.mkdir_p(parent_dir)
        end

        puts "Cloning repository: #{url} -> #{path}"
        stdout, stderr, status = Open3.capture3("git clone #{url} #{path}")

        unless status.success?
          raise ApplyError, "Failed to clone #{url}: #{stderr}"
        end
      end
    end
  end
end
