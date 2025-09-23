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
  
  def execute(config, dry_run: false)
    if config['install']
      install_homebrew(dry_run)
    end
    
    if config['update']
      update_homebrew(dry_run)
    end
    
    if config['taps']&.any?
      install_taps(config['taps'], dry_run)
    end
    
    if config['packages']&.any?
      install_packages(config['packages'], dry_run)
    end
    
    if config['casks']&.any?
      install_casks(config['casks'], dry_run)
    end
  end
  
  private
  
  def install_homebrew(dry_run)
    run_command(
      'test $(which brew) || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"',
      "Install Homebrew",
      dry_run: dry_run,
      check: "which brew"
    )
  end
  
  def update_homebrew(dry_run)
    run_command("brew update", "Update Homebrew", dry_run: dry_run)
  end
  
  def install_taps(taps, dry_run)
    taps.each do |tap|
      run_command(
        "brew tap | grep -q '^#{Regexp.escape(tap)}$' || brew tap #{tap}",
        "Add tap: #{tap}",
        dry_run: dry_run
      )
    end
  end
  
  def install_packages(packages, dry_run)
    return if packages.empty?
    
    # Install packages one by one to handle already-installed packages gracefully
    packages.each do |package|
      run_command(
        "brew list #{package} > /dev/null 2>&1 || brew install #{package}",
        "Install package: #{package}",
        dry_run: dry_run
      )
    end
  end
  
  def install_casks(casks, dry_run)
    return if casks.empty?
    
    # Install casks one by one to handle already-installed casks gracefully  
    casks.each do |cask|
      run_command(
        "brew list --cask #{cask} > /dev/null 2>&1 || brew install --cask #{cask}",
        "Install cask: #{cask}",
        dry_run: dry_run
      )
    end
  end
end