module Dots
  module Providers
    class ShProvider < Provider
      def validate_config
        errors = []

        unless config['command']
          errors << "ShProvider requires 'command' key"
        end

        if config['command'] && (!config['command'].is_a?(String) || config['command'].strip.empty?)
          errors << "ShProvider 'command' must be a non-empty string"
        end

        if config['interactive'] && !config['interactive'].is_a?(TrueClass) && !config['interactive'].is_a?(FalseClass)
          errors << "ShProvider 'interactive' must be a boolean"
        end

        errors.empty? ? true : errors
      end

      def apply
        if config['interactive']
          status = system(config['command'])
          
          unless status
            raise ApplyError, "Shell command failed with exit code #{$?.exitstatus}"
          end
        else
          stdout, stderr, status = Open3.capture3(config['command'])

          unless status.success?
            error_msg = "Shell command failed with exit code #{status.exitstatus}"
            error_msg += "\nSTDOUT: #{stdout}" unless stdout.empty?
            error_msg += "\nSTDERR: #{stderr}" unless stderr.empty?
            raise ApplyError, error_msg
          end

          puts stdout unless stdout.empty?
        end

        true
      end

      def describe
        command_preview = config['command'].strip.lines.first.strip
        command_preview = command_preview[0..60] + '...' if command_preview.length > 60
        "Run shell command: #{command_preview}"
      end
    end
  end
end