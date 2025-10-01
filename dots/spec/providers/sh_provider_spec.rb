require 'spec_helper'

RSpec.describe Dots::Providers::ShProvider do
  describe 'schema validation' do
    it 'requires command field' do
      provider = described_class.new({})
      errors = provider.validation_errors

      expect(errors).to include("Missing or invalid 'command'")
    end

    it 'accepts valid command' do
      provider = described_class.new({ 'command' => 'echo test' })
      expect(provider.valid?).to be true
    end

    it 'accepts optional interactive field' do
      provider = described_class.new({ 'command' => 'echo test', 'interactive' => true })
      expect(provider.valid?).to be true
    end

    it 'rejects invalid interactive field' do
      provider = described_class.new({ 'command' => 'echo test', 'interactive' => 'yes' })
      errors = provider.validation_errors

      expect(errors).to include(match(/'interactive' must be a boolean/))
    end

    it 'detects unknown properties' do
      provider = described_class.new({ 'command' => 'echo test', 'unknown' => 'value' })
      errors = provider.validation_errors

      expect(errors).to include('Unknown properties: unknown')
    end
  end

  describe '#describe' do
    it 'returns command preview' do
      provider = described_class.new({ 'command' => 'echo "hello world"' })
      expect(provider.describe).to eq('Run shell command: echo "hello world"')
    end

    it 'truncates long commands' do
      long_command = 'echo ' + 'a' * 100
      provider = described_class.new({ 'command' => long_command })
      description = provider.describe

      expect(description.length).to be < long_command.length + 20
      expect(description).to include('...')
    end
  end
end
