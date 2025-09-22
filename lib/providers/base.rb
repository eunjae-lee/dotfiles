class BaseProvider
  def validate(config)
    # Override in subclasses
    true
  end
  
  def merge(existing, new_config)
    # Default behavior: simple merge
    existing.merge(new_config)
  end
  
  protected
  
  def union_arrays(existing_array, new_array)
    (existing_array + new_array).uniq
  end
  
  def deep_merge_hashes(existing_hash, new_hash)
    existing_hash.merge(new_hash) do |key, old_val, new_val|
      if old_val.is_a?(Hash) && new_val.is_a?(Hash)
        deep_merge_hashes(old_val, new_val)
      else
        new_val
      end
    end
  end
end