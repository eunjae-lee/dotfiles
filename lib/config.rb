require_relative 'providers/homebrew'
require_relative 'providers/apps'
require_relative 'providers/default'

module Setup
  class Config
  PROVIDERS = {
    'homebrew' => HomebrewProvider,
    'apps' => AppsProvider,
    'vscode' => DefaultProvider,  # Add VSCodeProvider later
    'git' => DefaultProvider,     # Add GitProvider later
    'dotfiles' => DefaultProvider # Add DotfilesProvider later
  }.freeze
  
  def initialize
    @data = load_config
  end
  
  def applied_migrations
    @data['_applied_migrations'] || []
  end
  
  def pending_migrations
    all_migrations - applied_migrations
  end
  
  def validate!
    @data.each do |section, config|
      next if section == '_applied_migrations'
      validate_section(section, config)
    end
  end
  
  def merge_migration!(migration_name, migration_config)
    # Validate each section before merging
    migration_config.each do |section, config|
      validate_section(section, config)
    end
    
    # Merge with provider-specific logic
    migration_config.each do |section, new_config|
      if @data[section]
        @data[section] = merge_section(section, @data[section], new_config)
      else
        @data[section] = new_config
      end
    end
    
    # Track applied migration
    @data['_applied_migrations'] ||= []
    @data['_applied_migrations'] << migration_name
    
    save_config!
  end
  
  private
  
  def load_config
    if File.exist?('config.yml')
      YAML.load_file('config.yml') || {}
    else
      { '_applied_migrations' => [] }
    end
  end
  
  def save_config!
    File.write('config.yml', @data.to_yaml)
  end
  
  def all_migrations
    Dir.glob('migrations/*.yml').map do |file|
      File.basename(file, '.yml')
    end.sort
  end
  
  def validate_section(section, config)
    provider_class = PROVIDERS[section] || DefaultProvider
    provider = provider_class.new
    provider.validate(config)
  end
  
  def merge_section(section, existing, new_config)
    provider_class = PROVIDERS[section] || DefaultProvider
    provider = provider_class.new
    provider.merge(existing, new_config)
  end
  end
end