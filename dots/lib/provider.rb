module Dots
  class Provider
    attr_reader :config

    def initialize(config)
      @config = config
    end

    def validate_config
      raise NotImplementedError, "#{self.class} must implement #validate_config"
    end

    def valid?
      result = validate_config
      result == true || result.nil?
    end

    def validation_errors
      result = validate_config
      result == true || result.nil? ? [] : Array(result)
    end

    def apply
      raise NotImplementedError, "#{self.class} must implement #apply"
    end

    def describe
      raise NotImplementedError, "#{self.class} must implement #describe"
    end

    def self.for(provider_name, config)
      provider_class = case provider_name
      when 'sh'
        Providers::ShProvider
      when 'brew'
        Providers::BrewProvider
      when 'mas'
        Providers::MasProvider
      when 'repo'
        Providers::RepoProvider
      when 'symlink'
        Providers::SymlinkProvider
      else
        raise ValidationError, "Unknown provider: #{provider_name}"
      end

      provider_class.new(config)
    end
  end
end