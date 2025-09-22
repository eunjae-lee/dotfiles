require 'spec_helper'

RSpec.describe BaseProvider do
  let(:provider) { BaseProvider.new }

  describe '#validate' do
    it 'returns true by default' do
      expect(provider.validate({})).to be true
    end
  end

  describe '#merge' do
    it 'performs simple merge by default' do
      existing = { 'a' => 1, 'b' => 2 }
      new_config = { 'b' => 3, 'c' => 4 }
      
      result = provider.merge(existing, new_config)
      expect(result).to eq({ 'a' => 1, 'b' => 3, 'c' => 4 })
    end
  end

  describe '#union_arrays' do
    it 'combines arrays without duplicates' do
      existing = ['a', 'b', 'c']
      new_array = ['b', 'c', 'd']
      
      result = provider.send(:union_arrays, existing, new_array)
      expect(result).to eq(['a', 'b', 'c', 'd'])
    end

    it 'handles empty arrays' do
      result = provider.send(:union_arrays, [], ['a', 'b'])
      expect(result).to eq(['a', 'b'])
      
      result = provider.send(:union_arrays, ['a', 'b'], [])
      expect(result).to eq(['a', 'b'])
    end
  end

  describe '#deep_merge_hashes' do
    it 'performs deep merge of nested hashes' do
      existing = {
        'level1' => {
          'level2a' => { 'key1' => 'value1' },
          'level2b' => 'simple_value'
        }
      }
      new_hash = {
        'level1' => {
          'level2a' => { 'key2' => 'value2' },
          'level2c' => 'new_value'
        }
      }
      
      result = provider.send(:deep_merge_hashes, existing, new_hash)
      
      expect(result['level1']['level2a']).to eq({ 'key1' => 'value1', 'key2' => 'value2' })
      expect(result['level1']['level2b']).to eq('simple_value')
      expect(result['level1']['level2c']).to eq('new_value')
    end

    it 'overwrites non-hash values' do
      existing = { 'key' => 'old_value' }
      new_hash = { 'key' => 'new_value' }
      
      result = provider.send(:deep_merge_hashes, existing, new_hash)
      expect(result['key']).to eq('new_value')
    end
  end
end