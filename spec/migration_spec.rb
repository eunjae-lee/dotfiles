require 'spec_helper'
require 'yaml'
require 'tempfile'

RSpec.describe Setup::Migration do
  let(:migration_file) { 'test_migration.yml' }
  let(:migration_data) do
    {
      'name' => 'Test Migration',
      'description' => 'A test migration',
      'config' => {
        'homebrew' => {
          'packages' => ['git']
        }
      },
      'up' => [
        {
          'name' => 'Install git',
          'command' => 'echo "Installing git"',
          'check' => 'echo "Checking git"'
        }
      ]
    }
  end

  describe '#initialize' do
    it 'loads migration data from file' do
      allow(YAML).to receive(:load_file).with(migration_file).and_return(migration_data)
      allow(File).to receive(:basename).with(migration_file, '.yml').and_return('test_migration')
      
      migration = Setup::Migration.new(migration_file)
      
      expect(migration.name).to eq('test_migration')
      expect(migration.description).to eq('A test migration')
      expect(migration.config_data).to eq(migration_data['config'])
      expect(migration.commands).to eq(migration_data['up'])
    end

    it 'handles missing config section' do
      data = migration_data.dup
      data.delete('config')
      allow(YAML).to receive(:load_file).with(migration_file).and_return(data)
      allow(File).to receive(:basename).with(migration_file, '.yml').and_return('test_migration')
      
      migration = Setup::Migration.new(migration_file)
      expect(migration.config_data).to eq({})
    end

    it 'handles missing up section' do
      data = migration_data.dup
      data.delete('up')
      allow(YAML).to receive(:load_file).with(migration_file).and_return(data)
      allow(File).to receive(:basename).with(migration_file, '.yml').and_return('test_migration')
      
      migration = Setup::Migration.new(migration_file)
      expect(migration.commands).to eq([])
    end
  end

  describe '#apply' do
    let(:migration) do
      allow(YAML).to receive(:load_file).with(migration_file).and_return(migration_data)
      allow(File).to receive(:basename).with(migration_file, '.yml').and_return('test_migration')
      Setup::Migration.new(migration_file)
    end

    context 'in dry run mode' do
      it 'prints commands without executing them' do
        expect { migration.apply(dry_run: true) }.to output(/Installing git/).to_stdout
        expect { migration.apply(dry_run: true) }.to output(/dry-run - would execute/).to_stdout
      end
    end

    context 'in normal mode' do
      it 'executes commands' do
        expect(migration).to receive(:system).with('echo "Installing git"').and_return(true)
        expect(migration).to receive(:system).with('echo "Checking git"').and_return(true)
        
        expect { migration.apply }.not_to raise_error
      end

      it 'raises error when command fails' do
        expect(migration).to receive(:system).with('echo "Installing git"').and_return(false)
        
        expect { migration.apply }.to raise_error(/Command failed/)
      end
    end
  end

  describe '.apply_all' do
    let(:config) { instance_double(Setup::Config) }

    before do
      allow(Setup::Config).to receive(:new).and_return(config)
    end

    context 'when no pending migrations' do
      it 'prints no pending migrations message' do
        allow(config).to receive(:pending_migrations).and_return([])
        
        expect { Setup::Migration.apply_all }.to output(/No pending migrations/).to_stdout
      end
    end

    context 'when there are pending migrations' do
      before do
        allow(config).to receive(:pending_migrations).and_return(['test_migration'])
        allow(YAML).to receive(:load_file).with('migrations/test_migration.yml').and_return(migration_data)
        allow(File).to receive(:basename).with('migrations/test_migration.yml', '.yml').and_return('test_migration')
      end

      it 'applies all pending migrations in dry run mode' do
        expect { Setup::Migration.apply_all(dry_run: true) }.to output(/Applying 1 migration/).to_stdout
        expect(config).not_to receive(:merge_migration!)
      end

      it 'applies and merges migrations in normal mode' do
        allow_any_instance_of(Setup::Migration).to receive(:system).and_return(true)
        expect(config).to receive(:merge_migration!).with('test_migration', migration_data['config'])
        
        expect { Setup::Migration.apply_all }.to output(/All migrations applied successfully/).to_stdout
      end

      it 'only updates config in config-only mode' do
        expect(config).to receive(:merge_migration!).with('test_migration', migration_data['config'])
        
        expect { Setup::Migration.apply_all(config_only: true) }.to output(/Updating config only/).to_stdout
      end
    end
  end

  describe '.create' do
    it 'creates a new migration file with template' do
      allow(Time).to receive(:now).and_return(Time.new(2025, 1, 1, 12, 0, 0))
      allow(Dir).to receive(:exist?).with('migrations').and_return(true)
      allow(File).to receive(:write)
      
      expect { Setup::Migration.create('test_feature') }.to output(/Created migration/).to_stdout
    end

    it 'sanitizes migration name' do
      allow(Time).to receive(:now).and_return(Time.new(2025, 1, 1, 12, 0, 0))
      allow(Dir).to receive(:exist?).with('migrations').and_return(true)
      allow(File).to receive(:write)
      
      expect { Setup::Migration.create('test-feature with spaces!') }.to output(/Created migration/).to_stdout
    end
  end
end