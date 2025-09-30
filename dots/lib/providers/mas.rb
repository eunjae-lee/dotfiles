module Dots
  module Providers
    class MasProvider < Provider
      def validate_config
        unless config['apps'].is_a?(Array) && !config['apps'].empty?
          raise ValidationError, "MasProvider requires 'apps' array"
        end

        config['apps'].each_with_index do |app, index|
          unless app.is_a?(Hash)
            raise ValidationError, "MasProvider app at index #{index} must be a hash"
          end

          unless app['name'] && app['id']
            raise ValidationError, "MasProvider app at index #{index} must have 'name' and 'id'"
          end

          unless app['id'].is_a?(Integer) || (app['id'].is_a?(String) && app['id'].match?(/^\d+$/))
            raise ValidationError, "MasProvider app '#{app['name']}' must have numeric 'id'"
          end
        end

        true
      end

      def apply
        check_mas_installed

        config['apps'].each do |app|
          next if app_installed?(app['id'])

          puts "Installing app: #{app['name']} (#{app['id']})"
          stdout, stderr, status = Open3.capture3("mas install #{app['id']}")

          unless status.success?
            raise ApplyError, "Failed to install #{app['name']}: #{stderr}"
          end
        end

        true
      end

      def describe
        app_names = config['apps'].map { |app| app['name'] }.join(', ')
        "Install #{config['apps'].length} Mac App Store app(s): #{app_names}"
      end

      private

      def check_mas_installed
        stdout, stderr, status = Open3.capture3('which mas')
        unless status.success?
          raise ApplyError, "mas CLI is not installed. Install with: brew install mas"
        end
      end

      def app_installed?(app_id)
        stdout, stderr, status = Open3.capture3('mas list')
        status.success? && stdout.include?(app_id.to_s)
      end
    end
  end
end