require 'spec_helper'
require 'fileutils'
require 'tmpdir'

RSpec.describe Dots::StateManager do
  let(:temp_dir) { Dir.mktmpdir }
  let(:original_dir) { Dir.pwd }
  
  around do |example|
    Dir.chdir(temp_dir) do
      example.run
    end
  end
  
  let(:migrations_dir) { File.join(temp_dir, 'migrations') }
  let(:state_file) { File.join(migrations_dir, '.state.yml') }
  
  after do
    Dir.chdir(original_dir)
    FileUtils.rm_rf(temp_dir) if Dir.exist?(temp_dir)
  end

  describe '#migrations_dir' do
    it 'returns migrations directory path' do
      manager = described_class.new
      expect(File.realpath(manager.migrations_dir)).to eq(File.realpath(migrations_dir))
    end

    it 'creates migrations directory if it does not exist' do
      FileUtils.rm_rf(migrations_dir)
      described_class.new
      expect(Dir.exist?(migrations_dir)).to be true
    end
  end

  describe '#state_file' do
    it 'returns state file path' do
      manager = described_class.new
      expect(File.basename(manager.state_file)).to eq('.state.yml')
      expect(manager.state_file).to include('migrations')
    end
  end

  describe '#applied_migrations' do
    it 'returns empty array when no state file exists' do
      manager = described_class.new
      expect(manager.applied_migrations).to eq([])
    end

    it 'returns applied migrations from state file' do
      manager = described_class.new
      File.write(state_file, <<~YAML)
        ---
        - migration: 20240101_test.yml
          checksum: abc123
      YAML

      applied = manager.applied_migrations
      expect(applied.length).to eq(1)
      expect(applied.first['migration']).to eq('20240101_test.yml')
      expect(applied.first['checksum']).to eq('abc123')
    end
  end

  describe '#add_migration' do
    it 'adds migration to state file' do
      manager = described_class.new
      manager.add_migration('20240101_test.yml', 'checksum123')

      applied = manager.applied_migrations
      expect(applied.length).to eq(1)
      expect(applied.first['migration']).to eq('20240101_test.yml')
      expect(applied.first['checksum']).to eq('checksum123')
    end

    it 'appends to existing migrations' do
      manager = described_class.new
      manager.add_migration('20240101_first.yml', 'check1')
      manager.add_migration('20240102_second.yml', 'check2')

      applied = manager.applied_migrations
      expect(applied.length).to eq(2)
      expect(applied[0]['migration']).to eq('20240101_first.yml')
      expect(applied[1]['migration']).to eq('20240102_second.yml')
    end
  end

  describe '#pending_migrations' do
    it 'returns all migration files when none are applied' do
      manager = described_class.new
      File.write(File.join(migrations_dir, '20240101_test1.yml'), 'provider: sh')
      File.write(File.join(migrations_dir, '20240102_test2.yml'), 'provider: sh')

      pending = manager.pending_migrations
      expect(pending.length).to eq(2)
      expect(pending).to include('20240101_test1.yml', '20240102_test2.yml')
    end

    it 'excludes applied migrations' do
      manager = described_class.new
      File.write(File.join(migrations_dir, '20240101_test1.yml'), 'provider: sh')
      File.write(File.join(migrations_dir, '20240102_test2.yml'), 'provider: sh')
      
      manager.add_migration('20240101_test1.yml', 'check1')

      pending = manager.pending_migrations
      expect(pending.length).to eq(1)
      expect(pending).to eq(['20240102_test2.yml'])
    end

    it 'ignores .state.yml file' do
      manager = described_class.new
      File.write(File.join(migrations_dir, '20240101_test.yml'), 'provider: sh')

      pending = manager.pending_migrations
      expect(pending).to eq(['20240101_test.yml'])
    end
  end

  describe '#calculate_checksum' do
    it 'calculates SHA256 checksum of file' do
      manager = described_class.new
      test_file = File.join(migrations_dir, 'test.yml')
      File.write(test_file, 'test content')

      checksum = manager.calculate_checksum(test_file)
      expect(checksum).to be_a(String)
      expect(checksum.length).to eq(64) # SHA256 produces 64 hex characters
    end

    it 'produces same checksum for identical content' do
      manager = described_class.new
      test_file = File.join(migrations_dir, 'test.yml')
      File.write(test_file, 'test content')

      checksum1 = manager.calculate_checksum(test_file)
      checksum2 = manager.calculate_checksum(test_file)
      
      expect(checksum1).to eq(checksum2)
    end

    it 'produces different checksum for different content' do
      manager = described_class.new
      test_file1 = File.join(migrations_dir, 'test1.yml')
      test_file2 = File.join(migrations_dir, 'test2.yml')
      
      File.write(test_file1, 'content1')
      File.write(test_file2, 'content2')

      checksum1 = manager.calculate_checksum(test_file1)
      checksum2 = manager.calculate_checksum(test_file2)
      
      expect(checksum1).not_to eq(checksum2)
    end
  end

  describe '#find_checksum' do
    it 'returns checksum for applied migration' do
      manager = described_class.new
      manager.add_migration('20240101_test.yml', 'checksum123')

      checksum = manager.find_checksum('20240101_test.yml')
      expect(checksum).to eq('checksum123')
    end

    it 'returns nil for unapplied migration' do
      manager = described_class.new
      checksum = manager.find_checksum('nonexistent.yml')
      expect(checksum).to be_nil
    end
  end

  describe '#migration_path' do
    it 'returns full path to migration file' do
      manager = described_class.new
      path = manager.migration_path('test.yml')
      expect(File.basename(path)).to eq('test.yml')
      expect(path).to include('migrations')
    end
  end
end
