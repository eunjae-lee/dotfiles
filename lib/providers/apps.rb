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
  
  def execute(config, dry_run: false)
    if config['mas_apps']&.any?
      install_mas_apps(config['mas_apps'], dry_run)
    end
    
    if config['cask_apps']&.any?
      install_cask_apps(config['cask_apps'], dry_run)
    end
    
    if config['vscode_extensions']&.any?
      install_vscode_extensions(config['vscode_extensions'], dry_run)
    end
  end
  
  private
  
  def install_mas_apps(apps, dry_run)
    # Ensure mas is installed first
    run_command(
      "brew list mas > /dev/null 2>&1 || brew install mas",
      "Install mas (Mac App Store CLI)",
      dry_run: dry_run
    )
    
    apps.each do |app_id|
      run_command(
        "mas list | grep -q '^#{app_id}' || mas install #{app_id}",
        "Install Mac App Store app: #{app_id}",
        dry_run: dry_run
      )
    end
  end
  
  def install_cask_apps(apps, dry_run)
    return if apps.empty?
    
    apps.each do |app|
      run_command(
        "brew list --cask #{app} > /dev/null 2>&1 || brew install --cask #{app}",
        "Install cask application: #{app}",
        dry_run: dry_run
      )
    end
  end
  
  def install_vscode_extensions(extensions, dry_run)
    return if extensions.empty?
    
    extensions.each do |extension|
      run_command(
        "code --list-extensions | grep -q '^#{Regexp.escape(extension)}$' || code --install-extension #{extension}",
        "Install VSCode extension: #{extension}",
        dry_run: dry_run
      )
    end
  end
end