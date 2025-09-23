class BaseProvider
  def validate(config)
    # Override in subclasses
    true
  end
  
  def merge(existing, new_config)
    # Default behavior: simple merge
    existing.merge(new_config)
  end
  
  def execute(config, dry_run: false)
    # Override in subclasses to implement actual execution
    puts "    No execution implemented for #{self.class}"
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
  
  def run_command(command, description, dry_run: false, check: nil)
    puts "  → #{description}"
    
    if dry_run
      puts "    $ #{command}"
      puts "      (dry-run - would execute)"
      return true
    end
    
    success = system(command)
    unless success
      puts "    ✗ Failed: #{command}"
      return false
    end
    
    if check
      check_success = system(check)
      puts "    ✓ Verified" if check_success
      return check_success
    end
    
    puts "    ✓ Completed"
    true
  end
end