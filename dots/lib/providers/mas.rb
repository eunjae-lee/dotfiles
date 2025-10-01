module Dots
  module Providers
    class MasProvider < Provider
      def validate_config
        errors = []

        unless config['apps'].is_a?(Array) && !config['apps'].empty?
          errors << "MasProvider requires 'apps' array"
          return errors
        end

        config['apps'].each_with_index do |app, index|
          if app.is_a?(Integer) || (app.is_a?(String) && app.match?(/^\d+$/))
            next
          elsif app.is_a?(Hash)
            unless app['name'] && app['id']
              errors << "MasProvider app at index #{index} must have 'name' and 'id'"
            end

            if app['id'] && !(app['id'].is_a?(Integer) || (app['id'].is_a?(String) && app['id'].match?(/^\d+$/)))
              errors << "MasProvider app '#{app['name']}' must have numeric 'id'"
            end
          else
            errors << "MasProvider app at index #{index} must be a hash with 'name' and 'id', or a numeric id"
          end
        end

        errors.empty? ? true : errors
      end

      def apply
        check_mas_installed

        config['apps'].each do |app|
          app_id, app_name = normalize_app(app)
          
          next if app_installed?(app_id)

          puts "Installing app: #{app_name} (#{app_id})"
          stdout, stderr, status = Open3.capture3("mas install #{app_id}")

          unless status.success?
            raise ApplyError, "Failed to install #{app_name}: #{stderr}"
          end
        end

        true
      end

      def describe
        app_names = config['apps'].map do |app|
          app_id, app_name = normalize_app(app)
          app_name
        end.join(', ')
        "Install #{config['apps'].length} Mac App Store app(s): #{app_names}"
      end

      private

      def normalize_app(app)
        if app.is_a?(Integer) || (app.is_a?(String) && app.match?(/^\d+$/))
          [app.to_s, app.to_s]
        else
          [app['id'].to_s, app['name']]
        end
      end

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