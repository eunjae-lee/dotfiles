require 'spec_helper'

RSpec.describe Dots::Providers::MasProvider do
  describe 'schema validation' do
    it 'requires apps array' do
      provider = described_class.new({})
      errors = provider.validation_errors

      expect(errors).to include("Missing or invalid 'apps'")
    end

    it 'accepts integer app IDs' do
      provider = described_class.new({ 'apps' => [409183694, 497799835] })
      expect(provider.valid?).to be true
    end

    it 'accepts string app IDs' do
      provider = described_class.new({ 'apps' => ['409183694'] })
      expect(provider.valid?).to be true
    end

    it 'accepts hash with name and id' do
      provider = described_class.new({
        'apps' => [
          { 'name' => 'Xcode', 'id' => 497799835 }
        ]
      })

      expect(provider.valid?).to be true
    end

    it 'accepts mixed formats' do
      provider = described_class.new({
        'apps' => [
          409183694,
          { 'name' => 'Xcode', 'id' => 497799835 }
        ]
      })

      expect(provider.valid?).to be true
    end

    it 'detects unknown properties in app hash' do
      provider = described_class.new({
        'apps' => [
          { 'name' => 'Xcode', 'id' => 497799835, 'unknown' => 'value' }
        ]
      })
      errors = provider.validation_errors

      expect(errors).to include(match(/Unknown properties: unknown/))
    end

    it 'requires name and id in hash format' do
      provider = described_class.new({
        'apps' => [
          { 'name' => 'Xcode' }
        ]
      })
      errors = provider.validation_errors

      expect(errors).to include(match(/Missing or invalid 'id'/))
    end
  end

  describe '#describe' do
    it 'lists app names' do
      provider = described_class.new({
        'apps' => [
          { 'name' => 'Xcode', 'id' => 497799835 },
          { 'name' => 'Pages', 'id' => 409201541 }
        ]
      })

      expect(provider.describe).to eq('Install 2 Mac App Store app(s): Xcode, Pages')
    end

    it 'uses ID as name for integer format' do
      provider = described_class.new({ 'apps' => [409183694] })
      expect(provider.describe).to eq('Install 1 Mac App Store app(s): 409183694')
    end
  end
end
