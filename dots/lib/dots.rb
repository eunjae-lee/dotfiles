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

require_relative 'dots/provider'
require_relative 'dots/providers/sh'
require_relative 'dots/providers/brew'
require_relative 'dots/providers/mas'
require_relative 'dots/state_manager'
require_relative 'dots/migration_manager'
require_relative 'dots/cli'