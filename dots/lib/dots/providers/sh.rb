module Dots
  module Providers
    class ShProvider < Provider
      def validate_config
        unless config['command']
          raise ValidationError, "ShProvider requires 'command' key"
        end

        unless config['command'].is_a?(String) && !config['command'].strip.empty?
          raise ValidationError, "ShProvider 'command' must be a non-empty string"
        end

        true
      end

      def apply
        stdout, stderr, status = Open3.capture3(config['command'])

        unless status.success?
          error_msg = "Shell command failed with exit code #{status.exitstatus}"
          error_msg += "\nSTDOUT: #{stdout}" unless stdout.empty?
          error_msg += "\nSTDERR: #{stderr}" unless stderr.empty?
          raise ApplyError, error_msg
        end

        puts stdout unless stdout.empty?
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