module Dots
  module Providers
    class ShProvider < Provider
      def self.schema
        @schema ||= begin
          schema = ConfigSchema.new
          schema.field :command, type: :string, required: true
          schema.field :interactive, type: :boolean
          schema
        end
      end

      def apply
        command = expand_home(config['command'])
        
        if config['interactive']
          status = system('bash', '-c', command)
          
          unless status
            raise ApplyError, "Shell command failed with exit code #{$?.exitstatus}"
          end
        else
          stdout, stderr, status = Open3.capture3('bash', '-c', command)

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

      private

      def expand_home(command)
        command.gsub(/~(?=\/|")/, ENV['HOME'])
      end
    end
  end
end