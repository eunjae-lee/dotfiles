module Dots
  class ConfigSchema
    attr_reader :fields, :ignored_keys, :config_validators

    def initialize
      @fields = {}
      @ignored_keys = []
      @config_validators = []
    end

    def field(name, type:, required: false, array_item_schema: nil, custom_validator: nil)
      @fields[name.to_s] = {
        type: type,
        required: required,
        array_item_schema: array_item_schema,
        custom_validator: custom_validator
      }
    end

    def ignore(*keys)
      @ignored_keys.concat(keys.map(&:to_s))
    end

    def validate_with(&block)
      @config_validators << block
    end

    def validate(config, context: '')
      errors = []

      # Check for unknown keys
      allowed_keys = @fields.keys + @ignored_keys
      unknown_keys = config.keys - allowed_keys
      if unknown_keys.any?
        prefix = context.empty? ? '' : "#{context}: "
        errors << "#{prefix}Unknown properties: #{unknown_keys.join(', ')}"
      end

      # Validate each field
      @fields.each do |field_name, field_config|
        value = config[field_name]

        # Check required
        if field_config[:required] && (value.nil? || (value.is_a?(String) && value.strip.empty?))
          prefix = context.empty? ? '' : "#{context}: "
          errors << "#{prefix}Missing or invalid '#{field_name}'"
          next
        end

        next if value.nil?

        # Check type
        expected_type = field_config[:type]
        valid_type = case expected_type
        when :string
          value.is_a?(String) && !value.strip.empty?
        when :integer
          value.is_a?(Integer) || (value.is_a?(String) && value.match?(/^\d+$/))
        when :boolean
          value.is_a?(TrueClass) || value.is_a?(FalseClass)
        when :array
          value.is_a?(Array)
        when :hash
          value.is_a?(Hash)
        else
          true
        end

        unless valid_type
          prefix = context.empty? ? '' : "#{context}: "
          errors << "#{prefix}'#{field_name}' must be a #{expected_type}"
          next
        end

        # Custom validator
        if field_config[:custom_validator]
          custom_errors = field_config[:custom_validator].call(value, context)
          errors.concat(custom_errors) if custom_errors
        end

        # Validate array items
        if expected_type == :array && field_config[:array_item_schema]
          value.each_with_index do |item, index|
            item_context = context.empty? ? "Item at index #{index}" : "#{context} at index #{index}"
            item_errors = field_config[:array_item_schema].validate(item, context: item_context)
            errors.concat(item_errors)
          end
        end
      end

      # Run config-level validators
      @config_validators.each do |validator|
        validator_errors = validator.call(config)
        errors.concat(validator_errors) if validator_errors
      end

      errors
    end
  end
end
