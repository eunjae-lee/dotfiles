require_relative 'base'

class DefaultProvider < BaseProvider
  def validate(config)
    # Basic validation: ensure it's a hash
    raise "Config must be a hash" unless config.is_a?(Hash)
    true
  end
  
  def merge(existing, new_config)
    # Default merge strategy
    case
    when existing.is_a?(Array) && new_config.is_a?(Array)
      union_arrays(existing, new_config)
    when existing.is_a?(Hash) && new_config.is_a?(Hash)
      deep_merge_hashes(existing, new_config)
    when existing == new_config
      new_config  # Same value, no conflict
    else
      raise "Conflict: Can't merge #{existing.class}(#{existing}) with #{new_config.class}(#{new_config})"
    end
  end
end