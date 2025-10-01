require 'spec_helper'

RSpec.describe Dots::Providers::RepoProvider do
  describe 'schema validation' do
    it 'requires repos array' do
      provider = described_class.new({})
      errors = provider.validation_errors

      expect(errors).to include("Missing or invalid 'repos'")
    end

    it 'validates repo items have url and path' do
      provider = described_class.new({
        'repos' => [
          { 'url' => 'https://github.com/user/repo.git' }
        ]
      })
      errors = provider.validation_errors

      expect(errors).to include(match(/Missing or invalid 'path'/))
    end

    it 'accepts valid repos' do
      provider = described_class.new({
        'repos' => [
          { 'url' => 'https://github.com/user/repo.git', 'path' => '~/projects/repo' }
        ]
      })

      expect(provider.valid?).to be true
    end

    it 'detects unknown properties in repos' do
      provider = described_class.new({
        'repos' => [
          { 'url' => 'https://github.com/user/repo.git', 'path' => '~/repo', 'unknown' => 'value' }
        ]
      })
      errors = provider.validation_errors

      expect(errors).to include(match(/Unknown properties: unknown/))
    end
  end

  describe '#describe' do
    it 'returns repository count' do
      provider = described_class.new({
        'repos' => [
          { 'url' => 'https://github.com/user/repo1.git', 'path' => '~/repo1' },
          { 'url' => 'https://github.com/user/repo2.git', 'path' => '~/repo2' }
        ]
      })

      expect(provider.describe).to eq('Clone 2 git repositories')
    end

    it 'uses singular form for one repo' do
      provider = described_class.new({
        'repos' => [
          { 'url' => 'https://github.com/user/repo.git', 'path' => '~/repo' }
        ]
      })

      expect(provider.describe).to eq('Clone 1 git repository')
    end
  end
end
