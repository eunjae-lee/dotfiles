require_relative 'base'

class DotfilesProvider < BaseProvider
  SCHEMA = {
    'workspace_dir' => { type: 'string', required: false },
    'sandbox_dir' => { type: 'string', required: false },
    'repositories' => { 
      type: 'array', 
      items: {
        type: 'object',
        properties: {
          'url' => { type: 'string', required: true },
          'path' => { type: 'string', required: true }
        }
      }, 
      required: false 
    },
    'symlinks' => { 
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
    
    # Simple merge for string fields
    %w[workspace_dir sandbox_dir].each do |key|
      result[key] = new_config[key] if new_config.key?(key)
    end
    
    # Union arrays for repositories and symlinks
    %w[repositories symlinks].each do |key|
      if new_config[key]
        result[key] = union_arrays(existing[key] || [], new_config[key])
      end
    end
    
    result
  end
  
  def execute(config, dry_run: false)
    create_directories(config, dry_run)
    clone_repositories(config['repositories'], dry_run) if config['repositories']
    create_symlinks(config['symlinks'], dry_run) if config['symlinks']
  end
  
  private
  
  def create_directories(config, dry_run)
    dirs = []
    dirs << config['workspace_dir'] if config['workspace_dir']
    dirs << config['sandbox_dir'] if config['sandbox_dir']
    
    dirs.each do |dir|
      expanded_dir = File.expand_path(dir)
      run_command("mkdir -p #{expanded_dir}", "Create directory: #{dir}", dry_run: dry_run)
    end
  end
  
  def clone_repositories(repositories, dry_run)
    repositories.each do |repo|
      path = File.expand_path(repo['path'])
      run_command(
        "test -d #{path} || git clone #{repo['url']} #{path}",
        "Clone repository: #{repo['url']} -> #{repo['path']}",
        dry_run: dry_run
      )
    end
  end
  
  def create_symlinks(symlinks, dry_run)
    symlinks.each do |link|
      source = File.expand_path(link['source'])
      target = File.expand_path(link['target'])
      target_dir = File.dirname(target)
      
      # Create target directory if needed
      run_command("mkdir -p #{target_dir}", "Create directory for symlink: #{target_dir}", dry_run: dry_run)
      
      # Remove existing target and create symlink
      run_command(
        "rm -f #{target} && ln -sf #{source} #{target}",
        "Create symlink: #{link['source']} -> #{link['target']}",
        dry_run: dry_run
      )
    end
  end
end