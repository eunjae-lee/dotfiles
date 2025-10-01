require 'spec_helper'

RSpec.describe Dots::Providers::BrewProvider do
  describe 'schema validation' do
    it 'requires at least one of packages, casks, or taps' do
      provider = described_class.new({})
      errors = provider.validation_errors

      expect(errors).to include(match(/at least one of/))
    end

    it 'accepts packages only' do
      provider = described_class.new({ 'packages' => ['vim'] })
      expect(provider.valid?).to be true
    end

    it 'accepts casks only' do
      provider = described_class.new({ 'casks' => ['iterm2'] })
      expect(provider.valid?).to be true
    end

    it 'accepts taps only' do
      provider = described_class.new({ 'taps' => ['homebrew/cask-fonts'] })
      expect(provider.valid?).to be true
    end

    it 'accepts all three fields' do
      provider = described_class.new({
        'packages' => ['vim'],
        'casks' => ['iterm2'],
        'taps' => ['homebrew/cask-fonts']
      })

      expect(provider.valid?).to be true
    end

    it 'detects unknown properties' do
      provider = described_class.new({
        'packages' => ['vim'],
        'unknown' => 'value'
      })
      errors = provider.validation_errors

      expect(errors).to include('Unknown properties: unknown')
    end
  end

  describe '#describe' do
    it 'describes packages' do
      provider = described_class.new({ 'packages' => ['vim', 'git'] })
      expect(provider.describe).to eq('Install Homebrew 2 package(s)')
    end

    it 'describes multiple types' do
      provider = described_class.new({
        'packages' => ['vim'],
        'casks' => ['iterm2', 'vscode']
      })

      expect(provider.describe).to eq('Install Homebrew 1 package(s), 2 cask(s)')
    end
  end
end
