require 'yaml'
require 'fileutils'

module Setup
  class Error < StandardError; end
  class ConfigError < Error; end
  class MigrationError < Error; end
  
  autoload :CLI, File.expand_path('cli', __dir__)
  autoload :Config, File.expand_path('config', __dir__)
  autoload :Migration, File.expand_path('migration', __dir__)
  autoload :SimpleSchema, File.expand_path('schema', __dir__)
end

require_relative 'cli'
require_relative 'config'
require_relative 'migration'
require_relative 'schema'