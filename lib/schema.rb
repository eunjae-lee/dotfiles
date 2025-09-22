module Setup
  class SimpleSchema
  def self.validate(data, schema)
    schema.each do |key, rules|
      value = data[key]
      
      # Check required
      if rules[:required] && !data.key?(key)
        raise "Missing required key: #{key}"
      end
      
      next unless value # Skip validation if nil/missing
      
      # Check type
      case rules[:type]
      when 'string'
        raise "#{key} must be string" unless value.is_a?(String)
      when 'array'
        raise "#{key} must be array" unless value.is_a?(Array)
      when 'boolean'
        raise "#{key} must be boolean" unless [true, false].include?(value)
      when 'hash'
        raise "#{key} must be hash" unless value.is_a?(Hash)
      end
      
      # Check array items
      if rules[:items] && value.is_a?(Array)
        value.each_with_index do |item, index|
          case rules[:items]
          when 'string'
            raise "#{key}[#{index}] must be string" unless item.is_a?(String)
          when 'hash'
            # Could validate nested hash structure
          end
        end
      end
    end
  end
  end
end