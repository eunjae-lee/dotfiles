require 'spec_helper'
require 'fileutils'
require 'tmpdir'

RSpec.describe Dots::MigrationManager do
  let(:temp_dir) { Dir.mktmpdir }
  let(:original_dir) { Dir.pwd }
  
  around do |example|
    Dir.chdir(temp_dir) do
      example.run
    end
  end
  
  let(:migrations_dir) { File.join(temp_dir, 'migrations') }
  
  after do
    Dir.chdir(original_dir)
    FileUtils.rm_rf(temp_dir) if Dir.exist?(temp_dir)
  end

  describe '#create_migration' do
    it 'creates a migration file with timestamp' do
      manager = described_class.new
      filename = manager.create_migration('test migration')

      expect(filename).to match(/^\d{8}_\d{6}_test-migration\.yml$/)
      expect(File.exist?(File.join(migrations_dir, filename))).to be true
    end

    it 'normalizes migration name' do
      manager = described_class.new
      filename = manager.create_migration('Test Migration With Spaces')

      expect(filename).to include('test-migration-with-spaces')
    end

    it 'creates file with template content' do
      manager = described_class.new
      filename = manager.create_migration('test')
      content = File.read(File.join(migrations_dir, filename))

      expect(content).to include('# Migration: test')
      expect(content).to include('provider: sh')
    end

    it 'replaces __NAME__ placeholder in template' do
      manager = described_class.new
      filename = manager.create_migration('my migration')
      content = File.read(File.join(migrations_dir, filename))

      expect(content).to include('Migration: my migration')
      expect(content).not_to include('__NAME__')
    end
  end

  describe '#load_migration' do
    it 'loads migration as array of configs' do
      manager = described_class.new
      migration_file = File.join(migrations_dir, 'test.yml')
      File.write(migration_file, <<~YAML)
        provider: sh
        command: echo test
      YAML

      configs = manager.load_migration('test.yml')
      expect(configs).to be_an(Array)
      expect(configs.length).to eq(1)
      expect(configs.first['provider']).to eq('sh')
    end

    it 'loads multiple migrations from array format' do
      manager = described_class.new
      migration_file = File.join(migrations_dir, 'test.yml')
      File.write(migration_file, <<~YAML)
        - provider: sh
          command: echo test1
        - provider: sh
          command: echo test2
      YAML

      configs = manager.load_migration('test.yml')
      expect(configs.length).to eq(2)
    end

    it 'raises error for empty file' do
      manager = described_class.new
      migration_file = File.join(migrations_dir, 'test.yml')
      File.write(migration_file, '')

      expect {
        manager.load_migration('test.yml')
      }.to raise_error(Dots::ValidationError, /empty|must be a hash/)
    end

    it 'raises error for invalid YAML' do
      manager = described_class.new
      migration_file = File.join(migrations_dir, 'test.yml')
      File.write(migration_file, "invalid: yaml: content:")

      expect {
        manager.load_migration('test.yml')
      }.to raise_error(Dots::ValidationError, /Invalid YAML/)
    end
  end

  describe '#validate_migration' do
    it 'validates and returns migration providers' do
      manager = described_class.new
      migration_file = File.join(migrations_dir, 'test.yml')
      File.write(migration_file, <<~YAML)
        provider: sh
        command: echo test
      YAML

      migrations = manager.validate_migration('test.yml')
      expect(migrations.length).to eq(1)
      expect(migrations.first[:provider]).to be_a(Dots::Providers::ShProvider)
    end

    it 'raises error for invalid provider config' do
      manager = described_class.new
      migration_file = File.join(migrations_dir, 'test.yml')
      File.write(migration_file, <<~YAML)
        provider: sh
      YAML

      expect {
        manager.validate_migration('test.yml')
      }.to raise_error(Dots::ValidationError)
    end

    it 'raises error for unknown provider' do
      manager = described_class.new
      migration_file = File.join(migrations_dir, 'test.yml')
      File.write(migration_file, <<~YAML)
        provider: unknown
        config: test
      YAML

      expect {
        manager.validate_migration('test.yml')
      }.to raise_error(Dots::ValidationError, /Unknown provider/)
    end
  end

  describe '#extract_migration_name' do
    it 'extracts name from comment' do
      manager = described_class.new
      migration_file = File.join(migrations_dir, 'test.yml')
      File.write(migration_file, <<~YAML)
        # Migration: My Test Migration
        provider: sh
        command: echo test
      YAML

      name = manager.extract_migration_name('test.yml')
      expect(name).to eq('My Test Migration')
    end

    it 'falls back to filename when no comment' do
      manager = described_class.new
      migration_file = File.join(migrations_dir, '20240101_123456_test-migration.yml')
      File.write(migration_file, <<~YAML)
        provider: sh
        command: echo test
      YAML

      name = manager.extract_migration_name('20240101_123456_test-migration.yml')
      expect(name).to eq('test migration')
    end

    it 'handles filenames without timestamp' do
      manager = described_class.new
      migration_file = File.join(migrations_dir, 'simple-test.yml')
      File.write(migration_file, <<~YAML)
        provider: sh
        command: echo test
      YAML

      name = manager.extract_migration_name('simple-test.yml')
      expect(name).to eq('simple test')
    end
  end

  describe '#pending_migrations' do
    it 'returns list of pending migration files' do
      manager = described_class.new
      File.write(File.join(migrations_dir, '20240101_test1.yml'), 'provider: sh\ncommand: echo 1')
      File.write(File.join(migrations_dir, '20240102_test2.yml'), 'provider: sh\ncommand: echo 2')

      pending = manager.pending_migrations
      expect(pending.length).to eq(2)
    end
  end

  describe '#applied_count' do
    it 'returns number of applied migrations' do
      manager = described_class.new
      expect(manager.applied_count).to eq(0)

      manager.state_manager.add_migration('20240101_test.yml', 'checksum1')
      expect(manager.applied_count).to eq(1)

      manager.state_manager.add_migration('20240102_test.yml', 'checksum2')
      expect(manager.applied_count).to eq(2)
    end
  end

  describe '#apply_migration' do
    it 'applies migration and updates state' do
      manager = described_class.new
      migration_file = File.join(migrations_dir, 'test.yml')
      File.write(migration_file, <<~YAML)
        provider: sh
        command: echo test
      YAML

      expect {
        manager.apply_migration('test.yml')
      }.not_to raise_error

      expect(manager.applied_count).to eq(1)
    end

    it 'raises error if migration was modified after being applied' do
      manager = described_class.new
      migration_file = File.join(migrations_dir, 'test.yml')
      File.write(migration_file, <<~YAML)
        provider: sh
        command: echo test
      YAML

      manager.apply_migration('test.yml')
      
      # Modify the file
      File.write(migration_file, <<~YAML)
        provider: sh
        command: echo modified
      YAML

      expect {
        manager.apply_migration('test.yml')
      }.to raise_error(Dots::ValidationError, /modified/)
    end
  end
end
