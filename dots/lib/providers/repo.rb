module Dots
  module Providers
    class RepoProvider < Provider
      def self.schema
        @schema ||= ConfigSchema.new do
          required(:repos).value(:array) do
            required(:url).filled(:string)
            required(:path).filled(:string)
          end
        end
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
