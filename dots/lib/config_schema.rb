module Dots
  class ConfigSchema
    attr_reader :fields, :ignored_keys, :config_validators

    def initialize(&block)
      @fields = {}
      @ignored_keys = []
      @config_validators = []
      if block_given?
        if block.arity == 0
          instance_eval(&block)
        else
          instance_exec(self, &block)
        end
      end
    end

    # DSL methods for defining fields
    def required(name)
      FieldBuilder.new(self, name.to_s, required: true)
    end

    def optional(name)
      FieldBuilder.new(self, name.to_s, required: false)
    end

    def ignore(*keys)
      @ignored_keys.concat(keys.map(&:to_s))
    end

    def validate_with(&block)
      @config_validators << block
    end

    def at_least_one_of(*field_names)
      validate_with do |config|
        has_any = field_names.any? do |field|
          config[field.to_s].is_a?(Array) && !config[field.to_s].empty?
        end
        
        unless has_any
          field_list = field_names.map { |f| "'#{f}'" }.join(', ')
          ["Requires at least one of: #{field_list}"]
        else
          []
        end
      end
    end

    # Internal method called by FieldBuilder
    def add_field(name, config)
      @fields[name] = config
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

        # Validate array items with or-types
        if expected_type == :array && field_config[:array_item_or_types]
          or_validator = field_config[:array_item_or_types]
          value.each_with_index do |item, index|
            unless or_validator.valid?(item, index)
              # Try validating as hash with schemas
              if item.is_a?(Hash) && or_validator.schemas.any?
                hash_errors = or_validator.validate_hash(item, index)
                errors.concat(hash_errors) unless hash_errors.empty?
              else
                item_context = context.empty? ? "Item at index #{index}" : "#{context} at index #{index}"
                type_names = or_validator.types.map(&:to_s).join(' or ')
                errors << "#{item_context}: must be a #{type_names}"
              end
            end
          end
        end

        # Validate array items
        if expected_type == :array && field_config[:array_item_type]
          value.each_with_index do |item, index|
            item_valid = case field_config[:array_item_type]
            when :string
              item.is_a?(String) && !item.strip.empty?
            when :integer
              item.is_a?(Integer) || (item.is_a?(String) && item.match?(/^\d+$/))
            when :hash
              item.is_a?(Hash)
            else
              true
            end

            unless item_valid
              item_context = context.empty? ? "Item at index #{index}" : "#{context} at index #{index}"
              errors << "#{item_context}: must be a #{field_config[:array_item_type]}"
            end
          end
        end

        # Validate array items with schema
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

    class FieldBuilder
      def initialize(schema, name, required:)
        @schema = schema
        @name = name
        @config = { required: required }
      end

      def filled(type = nil, &block)
        if type
          @config[:type] = type
        end
        if block_given?
          @config[:custom_validator] = block
        end
        @schema.add_field(@name, @config)
        self
      end

      def each(type_or_schema = nil, &block)
        @config[:type] = :array
        
        if block_given?
          # Block defines array item schema
          @config[:array_item_schema] = ConfigSchema.new(&block)
        elsif type_or_schema.is_a?(TypeOr)
          @config[:array_item_or_types] = type_or_schema
        elsif type_or_schema
          @config[:array_item_type] = type_or_schema
        end
        
        @schema.add_field(@name, @config)
        self
      end

      def value(type, &block)
        @config[:type] = type
        if block_given?
          if type == :array
            # Block defines array item schema
            @config[:array_item_schema] = ConfigSchema.new(&block)
          else
            @config[:custom_validator] = block
          end
        end
        @schema.add_field(@name, @config)
        self
      end

      def array(item_type)
        @config[:type] = :array
        if item_type.is_a?(Symbol)
          @config[:array_item_type] = item_type
        elsif item_type.is_a?(ConfigSchema)
          @config[:array_item_schema] = item_type
        end
        @schema.add_field(@name, @config)
        self
      end

      def hash(&block)
        @config[:type] = :hash
        if block_given?
          @config[:array_item_schema] = ConfigSchema.new(&block)
        end
        @schema.add_field(@name, @config)
        self
      end

    end

    class TypeOr
      attr_reader :types, :schemas

      def initialize(*types_or_schemas)
        @types = []
        @schemas = []
        
        types_or_schemas.each do |item|
          if item.is_a?(Symbol)
            @types << item
          elsif item.is_a?(ConfigSchema)
            @schemas << item
          elsif item.is_a?(Proc)
            @schemas << item
          end
        end
      end

      def valid?(value, index)
        # Check if value matches any of the types
        @types.any? do |type|
          case type
          when :integer
            value.is_a?(Integer) || (value.is_a?(String) && value.match?(/^\d+$/))
          when :string
            value.is_a?(String) && !value.strip.empty?
          when :hash
            value.is_a?(Hash)
          else
            false
          end
        end
      end

      def validate_hash(value, index)
        errors = []
        @schemas.each do |schema_or_proc|
          schema = schema_or_proc.is_a?(ConfigSchema) ? schema_or_proc : ConfigSchema.new(&schema_or_proc)
          item_errors = schema.validate(value, context: "Item at index #{index}")
          return [] if item_errors.empty? # Valid if any schema passes
          errors.concat(item_errors)
        end
        errors
      end
    end

    def self.or(*types_or_schemas)
      TypeOr.new(*types_or_schemas)
    end
  end
end
