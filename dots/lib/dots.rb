require 'yaml'
require 'fileutils'
require 'digest'
require 'open3'

module Dots
  class Error < StandardError; end
  class ValidationError < Error; end
  class ApplyError < Error; end
  class StateError < Error; end
end

require_relative 'config_schema'
require_relative 'provider'
require_relative 'providers/sh'
require_relative 'providers/brew'
require_relative 'providers/mas'
require_relative 'providers/repo'
require_relative 'providers/symlink'
require_relative 'state_manager'
require_relative 'migration_manager'
require_relative 'cli'