require_relative 'base'

class ZshProvider < BaseProvider
  SCHEMA = {
    'oh_my_zsh' => { type: 'boolean', required: false },
    'theme' => { type: 'string', required: false },
    'plugins' => { type: 'array', items: 'string', required: false },
    'dotfiles' => { 
      type: 'array', 
      items: {
        type: 'object',
        properties: {
          'source' => { type: 'string', required: true },
          'target' => { type: 'string', required: true }
        }
      }, 
      required: false 
    }
  }
  
  def validate(config)
    Setup::SimpleSchema.validate(config, SCHEMA)
  end
  
  def merge(existing, new_config)
    result = existing.dup
    
    # Simple merge for boolean and string fields
    %w[oh_my_zsh theme].each do |key|
      result[key] = new_config[key] if new_config.key?(key)
    end
    
    # Union arrays for plugins and dotfiles
    %w[plugins dotfiles].each do |key|
      if new_config[key]
        result[key] = union_arrays(existing[key] || [], new_config[key])
      end
    end
    
    result
  end
  
  def execute(config, dry_run: false)
    if config['oh_my_zsh']
      install_oh_my_zsh(dry_run)
    end
    
    if config['theme']
      install_theme(config['theme'], dry_run)
    end
    
    if config['plugins']&.any?
      install_plugins(config['plugins'], dry_run)
    end
    
    if config['dotfiles']&.any?
      setup_dotfiles(config['dotfiles'], dry_run)
    end
  end
  
  private
  
  def install_oh_my_zsh(dry_run)
    run_command(
      'test -d ~/.oh-my-zsh || sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended',
      "Install Oh My Zsh",
      dry_run: dry_run
    )
  end
  
  def install_theme(theme, dry_run)
    case theme
    when 'spaceship'
      run_command(
        'test -d "$ZSH_CUSTOM/themes/spaceship-prompt" || git clone https://github.com/spaceship-prompt/spaceship-prompt.git "$ZSH_CUSTOM/themes/spaceship-prompt" --depth=1',
        "Install spaceship prompt theme",
        dry_run: dry_run
      )
      
      run_command(
        'ln -sf "$ZSH_CUSTOM/themes/spaceship-prompt/spaceship.zsh-theme" "$ZSH_CUSTOM/themes/spaceship.zsh-theme"',
        "Link spaceship theme",
        dry_run: dry_run
      )
    else
      puts "    Theme '#{theme}' not implemented yet"
    end
  end
  
  def install_plugins(plugins, dry_run)
    plugins.each do |plugin|
      case plugin
      when 'zsh-z'
        run_command(
          'test -d $ZSH_CUSTOM/plugins/zsh-z || git clone https://github.com/agkozak/zsh-z $ZSH_CUSTOM/plugins/zsh-z',
          "Install zsh-z plugin",
          dry_run: dry_run
        )
      else
        puts "    Plugin '#{plugin}' not implemented yet"
      end
    end
  end
  
  def setup_dotfiles(dotfiles, dry_run)
    dotfiles.each do |dotfile|
      source = File.expand_path(dotfile['source'])
      target = File.expand_path(dotfile['target'])
      
      run_command(
        "rm -f #{target} && ln -sf #{source} #{target}",
        "Symlink zsh config: #{dotfile['source']} -> #{dotfile['target']}",
        dry_run: dry_run
      )
    end
  end
end