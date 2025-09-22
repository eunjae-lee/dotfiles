require_relative 'base'

class HomebrewProvider < BaseProvider
  SCHEMA = {
    'install' => { type: 'boolean', required: false },
    'update' => { type: 'boolean', required: false },
    'packages' => { type: 'array', items: 'string', required: false },
    'casks' => { type: 'array', items: 'string', required: false },
    'taps' => { type: 'array', items: 'string', required: false }
  }
  
  def validate(config)
    Setup::SimpleSchema.validate(config, SCHEMA)
  end
  
  def merge(existing, new_config)
    result = existing.dup
    
    # Union arrays for packages, casks, taps
    %w[packages casks taps].each do |key|
      if new_config[key]
        result[key] = union_arrays(existing[key] || [], new_config[key])
      end
    end
    
    # Simple merge for boolean flags
    %w[install update].each do |key|
      result[key] = new_config[key] if new_config.key?(key)
    end
    
    result
  end
end