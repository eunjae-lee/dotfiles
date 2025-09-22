require 'spec_helper'

RSpec.describe AppsProvider do
  let(:provider) { AppsProvider.new }

  describe '#validate' do
    it 'validates correct apps configuration' do
      config = {
        'mas_apps' => ['123456789', '987654321'],
        'cask_apps' => ['firefox', 'chrome'],
        'vscode_extensions' => ['ms-python.python', 'ms-vscode.cpptools']
      }
      
      expect { provider.validate(config) }.not_to raise_error
    end

    it 'validates configuration with missing optional fields' do
      config = {
        'mas_apps' => ['123456789']
      }
      
      expect { provider.validate(config) }.not_to raise_error
    end

    it 'raises error for invalid array types' do
      config = {
        'mas_apps' => 'not_an_array'
      }
      
      expect { provider.validate(config) }.to raise_error
    end
  end

  describe '#merge' do
    it 'merges mas_apps arrays without duplicates' do
      existing = {
        'mas_apps' => ['123456789', '111111111']
      }
      new_config = {
        'mas_apps' => ['111111111', '222222222']
      }
      
      result = provider.merge(existing, new_config)
      expect(result['mas_apps']).to eq(['123456789', '111111111', '222222222'])
    end

    it 'merges vscode_extensions arrays' do
      existing = {
        'vscode_extensions' => ['ms-python.python']
      }
      new_config = {
        'vscode_extensions' => ['ms-vscode.cpptools']
      }
      
      result = provider.merge(existing, new_config)
      expect(result['vscode_extensions']).to eq(['ms-python.python', 'ms-vscode.cpptools'])
    end

    it 'handles missing arrays in existing config' do
      existing = {}
      new_config = {
        'cask_apps' => ['firefox']
      }
      
      result = provider.merge(existing, new_config)
      expect(result['cask_apps']).to eq(['firefox'])
    end

    it 'preserves existing config when new config is empty' do
      existing = {
        'mas_apps' => ['123456789'],
        'vscode_extensions' => ['ms-python.python']
      }
      new_config = {}
      
      result = provider.merge(existing, new_config)
      expect(result).to eq(existing)
    end
  end
end