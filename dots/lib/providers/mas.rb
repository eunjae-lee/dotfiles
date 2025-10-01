module Dots
  module Providers
    class MasProvider < Provider
      def self.schema
        @schema ||= begin
          app_hash_schema = ConfigSchema.new do
            required(:name).filled(:string)
            required(:id).value(:integer)
          end
          
          ConfigSchema.new do
            required(:apps).value(:array).each(
              ConfigSchema.or(:integer, app_hash_schema)
            )
          end
        end
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