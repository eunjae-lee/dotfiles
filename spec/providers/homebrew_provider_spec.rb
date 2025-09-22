require 'spec_helper'

RSpec.describe HomebrewProvider do
  let(:provider) { HomebrewProvider.new }

  describe '#validate' do
    it 'validates correct homebrew configuration' do
      config = {
        'install' => true,
        'update' => false,
        'packages' => ['git', 'vim'],
        'casks' => ['firefox', 'chrome'],
        'taps' => ['homebrew/cask-fonts']
      }
      
      expect { provider.validate(config) }.not_to raise_error
    end

    it 'validates configuration with missing optional fields' do
      config = {
        'packages' => ['git']
      }
      
      expect { provider.validate(config) }.not_to raise_error
    end

    it 'raises error for invalid types' do
      config = {
        'packages' => 'not_an_array'
      }
      
      expect { provider.validate(config) }.to raise_error
    end

    it 'raises error for invalid boolean values' do
      config = {
        'install' => 'not_boolean'
      }
      
      expect { provider.validate(config) }.to raise_error
    end
  end

  describe '#merge' do
    it 'merges packages arrays without duplicates' do
      existing = {
        'packages' => ['git', 'vim']
      }
      new_config = {
        'packages' => ['vim', 'tmux']
      }
      
      result = provider.merge(existing, new_config)
      expect(result['packages']).to eq(['git', 'vim', 'tmux'])
    end

    it 'merges casks and taps arrays' do
      existing = {
        'casks' => ['firefox'],
        'taps' => ['homebrew/core']
      }
      new_config = {
        'casks' => ['chrome'],
        'taps' => ['homebrew/cask']
      }
      
      result = provider.merge(existing, new_config)
      expect(result['casks']).to eq(['firefox', 'chrome'])
      expect(result['taps']).to eq(['homebrew/core', 'homebrew/cask'])
    end

    it 'overwrites boolean flags' do
      existing = {
        'install' => false,
        'update' => true
      }
      new_config = {
        'install' => true
      }
      
      result = provider.merge(existing, new_config)
      expect(result['install']).to be true
      expect(result['update']).to be true  # preserved from existing
    end

    it 'handles missing arrays in existing config' do
      existing = {}
      new_config = {
        'packages' => ['git']
      }
      
      result = provider.merge(existing, new_config)
      expect(result['packages']).to eq(['git'])
    end

    it 'preserves existing config when new config is empty' do
      existing = {
        'packages' => ['git', 'vim'],
        'install' => true
      }
      new_config = {}
      
      result = provider.merge(existing, new_config)
      expect(result).to eq(existing)
    end
  end
end