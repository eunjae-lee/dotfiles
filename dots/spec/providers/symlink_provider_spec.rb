require 'spec_helper'

RSpec.describe Dots::Providers::SymlinkProvider do
  describe 'schema validation' do
    it 'requires links array' do
      provider = described_class.new({})
      errors = provider.validation_errors

      expect(errors).to include("Missing or invalid 'links'")
    end

    it 'validates link items have source and target' do
      provider = described_class.new({
        'links' => [
          { 'source' => '/tmp/source' }
        ]
      })
      errors = provider.validation_errors

      expect(errors).to include(match(/Missing or invalid 'target'/))
    end

    it 'accepts valid links' do
      provider = described_class.new({
        'links' => [
          { 'source' => '/tmp/source', 'target' => '/tmp/target' }
        ]
      })

      expect(provider.valid?).to be true
    end

    it 'accepts force option' do
      provider = described_class.new({
        'links' => [
          { 'source' => '/tmp/source', 'target' => '/tmp/target', 'force' => true }
        ]
      })

      expect(provider.valid?).to be true
    end

    it 'detects unknown properties in links' do
      provider = described_class.new({
        'links' => [
          { 'source' => '/tmp/source', 'target' => '/tmp/target', 'unknown' => 'value' }
        ]
      })
      errors = provider.validation_errors

      expect(errors).to include(match(/Unknown properties: unknown/))
    end
  end

  describe '#describe' do
    it 'returns symlink count' do
      provider = described_class.new({
        'links' => [
          { 'source' => '/tmp/a', 'target' => '/tmp/b' },
          { 'source' => '/tmp/c', 'target' => '/tmp/d' }
        ]
      })

      expect(provider.describe).to eq('Create 2 symlinks')
    end

    it 'uses singular form for one link' do
      provider = described_class.new({
        'links' => [
          { 'source' => '/tmp/a', 'target' => '/tmp/b' }
        ]
      })

      expect(provider.describe).to eq('Create 1 symlink')
    end
  end
end
