require_relative 'base'

class AppsProvider < BaseProvider
  SCHEMA = {
    'mas_apps' => { type: 'array', items: 'string', required: false },
    'cask_apps' => { type: 'array', items: 'string', required: false },
    'vscode_extensions' => { type: 'array', items: 'string', required: false }
  }
  
  def validate(config)
    Setup::SimpleSchema.validate(config, SCHEMA)
  end
  
  def merge(existing, new_config)
    result = existing.dup
    
    # Union arrays for app lists
    %w[mas_apps cask_apps vscode_extensions].each do |key|
      if new_config[key]
        result[key] = union_arrays(existing[key] || [], new_config[key])
      end
    end
    
    result
  end
end