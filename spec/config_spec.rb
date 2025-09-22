require 'spec_helper'
require 'yaml'
require 'tempfile'

RSpec.describe Setup::Config do

  describe '#initialize' do
    it 'loads existing configuration when file exists' do
      # Mock file existence and content
      allow(File).to receive(:exist?).with('config.yml').and_return(true)
      allow(File).to receive(:exist?).with('.local_state.yml').and_return(false)
      allow(YAML).to receive(:load_file).with('config.yml').and_return({ 'homebrew' => { 'packages' => ['vim'] } })
      
      config = Setup::Config.new
      expect(config.instance_variable_get(:@data)['homebrew']['packages']).to eq(['vim'])
    end

    it 'creates empty configuration when file does not exist' do
      allow(File).to receive(:exist?).with('config.yml').and_return(false)
      allow(File).to receive(:exist?).with('.local_state.yml').and_return(false)
      
      config = Setup::Config.new
      expect(config.instance_variable_get(:@data)).to eq({})
      expect(config.instance_variable_get(:@local_state)).to eq({ 'applied_migrations' => [] })
    end
  end

  describe '#applied_migrations' do
    it 'returns applied migrations from local state' do
      allow(File).to receive(:exist?).with('config.yml').and_return(false)
      allow(File).to receive(:exist?).with('.local_state.yml').and_return(true)
      allow(YAML).to receive(:load_file).with('.local_state.yml').and_return({ 'applied_migrations' => ['20250101_test'] })
      
      config = Setup::Config.new
      expect(config.applied_migrations).to eq(['20250101_test'])
    end

    it 'returns empty array when no migrations applied' do
      allow(File).to receive(:exist?).with('config.yml').and_return(false)
      allow(File).to receive(:exist?).with('.local_state.yml').and_return(false)
      
      config = Setup::Config.new
      expect(config.applied_migrations).to eq([])
    end
  end

  describe '#pending_migrations' do
    it 'returns migrations not yet applied' do
      allow(File).to receive(:exist?).with('config.yml').and_return(false)
      allow(File).to receive(:exist?).with('.local_state.yml').and_return(true)
      allow(YAML).to receive(:load_file).with('.local_state.yml').and_return({ 'applied_migrations' => ['20250101_test'] })
      allow(Dir).to receive(:glob).with('migrations/*.yml').and_return(['migrations/20250101_test.yml', 'migrations/20250102_test.yml'])
      
      config = Setup::Config.new
      expect(config.pending_migrations).to eq(['20250102_test'])
    end

    it 'returns all migrations when none applied' do
      allow(File).to receive(:exist?).with('config.yml').and_return(false)
      allow(File).to receive(:exist?).with('.local_state.yml').and_return(false)
      allow(Dir).to receive(:glob).with('migrations/*.yml').and_return(['migrations/20250101_test.yml', 'migrations/20250102_test.yml'])
      
      config = Setup::Config.new
      expect(config.pending_migrations.sort).to eq(['20250101_test', '20250102_test'])
    end
  end

  describe '#validate!' do
    it 'validates all configuration sections' do
      allow(File).to receive(:exist?).with('config.yml').and_return(true)
      allow(File).to receive(:exist?).with('.local_state.yml').and_return(false)
      allow(YAML).to receive(:load_file).with('config.yml').and_return({
        'homebrew' => { 'packages' => ['git'] },
        'apps' => { 'mas_apps' => ['123456'] }
      })
      
      config = Setup::Config.new
      expect { config.validate! }.not_to raise_error
    end

    it 'raises error for invalid configuration' do
      allow(File).to receive(:exist?).with('config.yml').and_return(true)
      allow(File).to receive(:exist?).with('.local_state.yml').and_return(false)
      allow(YAML).to receive(:load_file).with('config.yml').and_return({ 'homebrew' => { 'packages' => 'not_an_array' } })
      
      config = Setup::Config.new
      expect { config.validate! }.to raise_error(RuntimeError, /packages must be array/)
    end
  end

  describe '#merge_migration!' do
    it 'merges migration configuration into existing config and updates local state' do
      allow(File).to receive(:exist?).with('config.yml').and_return(true)
      allow(File).to receive(:exist?).with('.local_state.yml').and_return(false)
      allow(YAML).to receive(:load_file).with('config.yml').and_return({ 'homebrew' => { 'packages' => ['vim'] } })
      allow(File).to receive(:write)
      
      config = Setup::Config.new
      config.merge_migration!('20250101_test', { 'homebrew' => { 'packages' => ['git'] } })
      
      data = config.instance_variable_get(:@data)
      local_state = config.instance_variable_get(:@local_state)
      expect(data['homebrew']['packages']).to include('vim', 'git')
      expect(local_state['applied_migrations']).to include('20250101_test')
    end

    it 'creates new section if it does not exist' do
      allow(File).to receive(:exist?).with('config.yml').and_return(false)
      allow(File).to receive(:exist?).with('.local_state.yml').and_return(false)
      allow(File).to receive(:write)
      
      config = Setup::Config.new
      config.merge_migration!('20250102_test', { 'apps' => { 'mas_apps' => ['123456'] } })
      
      data = config.instance_variable_get(:@data)
      local_state = config.instance_variable_get(:@local_state)
      expect(data['apps']['mas_apps']).to eq(['123456'])
      expect(local_state['applied_migrations']).to include('20250102_test')
    end
  end
end