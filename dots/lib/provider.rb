module Dots
  class Provider
    attr_reader :config

    def initialize(config)
      @config = config
    end

    def self.schema
      raise NotImplementedError, "#{self.class} must implement .schema"
    end

    def validate_config
      # Always ignore 'provider' key since it's part of the migration config
      schema = self.class.schema
      schema.ignore :provider unless schema.ignored_keys.include?('provider')
      
      errors = schema.validate(config)
      errors.empty? ? true : errors
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