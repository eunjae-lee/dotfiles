module Dots
  module Providers
    class BrewProvider < Provider
      def self.schema
        @schema ||= begin
          schema = ConfigSchema.new
          schema.field :packages, type: :array
          schema.field :casks, type: :array
          schema.field :taps, type: :array
          
          schema.validate_with do |config|
            has_packages = config['packages'].is_a?(Array) && !config['packages'].empty?
            has_casks = config['casks'].is_a?(Array) && !config['casks'].empty?
            has_taps = config['taps'].is_a?(Array) && !config['taps'].empty?

            unless has_packages || has_casks || has_taps
              ["BrewProvider requires at least one of: 'packages', 'casks', or 'taps'"]
            else
              []
            end
          end
          
          schema
        end
      end

      def apply
        check_brew_installed

        install_taps if config['taps']
        install_packages if config['packages']
        install_casks if config['casks']

        true
      end

      def describe
        parts = []
        parts << "#{config['taps'].length} tap(s)" if config['taps']
        parts << "#{config['packages'].length} package(s)" if config['packages']
        parts << "#{config['casks'].length} cask(s)" if config['casks']
        "Install Homebrew #{parts.join(', ')}"
      end

      private

      def check_brew_installed
        stdout, stderr, status = Open3.capture3('which brew')
        unless status.success?
          raise ApplyError, "Homebrew is not installed. Install from https://brew.sh"
        end
      end

      def install_taps
        config['taps'].each do |tap|
          next if tap_installed?(tap)
          
          puts "Installing tap: #{tap}"
          stdout, stderr, status = Open3.capture3("brew tap #{tap}")
          
          unless status.success?
            raise ApplyError, "Failed to tap #{tap}: #{stderr}"
          end
        end
      end

      def install_packages
        config['packages'].each do |package|
          next if package_installed?(package)

          puts "Installing package: #{package}"
          stdout, stderr, status = Open3.capture3("brew install #{package}")

          unless status.success?
            raise ApplyError, "Failed to install #{package}: #{stderr}"
          end
        end
      end

      def install_casks
        config['casks'].each do |cask|
          next if cask_installed?(cask)

          puts "Installing cask: #{cask}"
          stdout, stderr, status = Open3.capture3("brew install --cask #{cask}")

          unless status.success?
            raise ApplyError, "Failed to install cask #{cask}: #{stderr}"
          end
        end
      end

      def tap_installed?(tap)
        stdout, stderr, status = Open3.capture3('brew tap')
        status.success? && stdout.include?(tap)
      end

      def package_installed?(package)
        stdout, stderr, status = Open3.capture3("brew list --formula #{package}")
        status.success?
      end

      def cask_installed?(cask)
        stdout, stderr, status = Open3.capture3("brew list --cask #{cask}")
        status.success?
      end
    end
  end
end