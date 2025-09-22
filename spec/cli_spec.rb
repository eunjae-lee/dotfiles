require 'spec_helper'

RSpec.describe Setup::CLI do
  let(:stdout) { StringIO.new }
  
  before do
    allow($stdout).to receive(:write) { |str| stdout.write(str) }
    allow($stdout).to receive(:puts) { |str| stdout.puts(str) }
  end

  describe '#initialize' do
    it 'parses command and flags correctly' do
      cli = Setup::CLI.new(['apply', '--dry-run', 'extra'])
      
      expect(cli.instance_variable_get(:@command)).to eq('apply')
      expect(cli.instance_variable_get(:@dry_run)).to be true
      expect(cli.instance_variable_get(:@config_only)).to be false
    end

    it 'parses update-config flag' do
      cli = Setup::CLI.new(['apply', '--update-config'])
      
      expect(cli.instance_variable_get(:@config_only)).to be true
      expect(cli.instance_variable_get(:@dry_run)).to be false
    end

    it 'extracts migration name for create command' do
      cli = Setup::CLI.new(['create', 'test_migration', '--dry-run'])
      
      expect(cli.instance_variable_get(:@migration_name)).to eq('test_migration')
    end
  end

  describe '#run' do
    context 'apply command' do
      it 'calls Migration.apply_all with correct flags' do
        expect(Setup::Migration).to receive(:apply_all).with(dry_run: true, config_only: false)
        
        cli = Setup::CLI.new(['apply', '--dry-run'])
        cli.run
      end

      it 'displays appropriate headers for dry run' do
        allow(Setup::Migration).to receive(:apply_all)
        
        cli = Setup::CLI.new(['apply', '--dry-run'])
        cli.run
        
        output = stdout.string
        expect(output).to include('Setup - Apply Migrations')
        expect(output).to include('DRY RUN MODE')
      end

      it 'displays appropriate headers for update-config' do
        allow(Setup::Migration).to receive(:apply_all)
        
        cli = Setup::CLI.new(['apply', '--update-config'])
        cli.run
        
        output = stdout.string
        expect(output).to include('UPDATE CONFIG MODE')
      end
    end

    context 'create command' do
      it 'calls Migration.create with migration name' do
        expect(Setup::Migration).to receive(:create).with('test_migration')
        
        cli = Setup::CLI.new(['create', 'test_migration'])
        cli.run
      end

      it 'shows error when migration name is missing' do
        expect { Setup::CLI.new(['create']).run }.to raise_error(SystemExit)
      end
    end

    context 'validate command' do
      it 'validates configuration and shows success message' do
        config = instance_double(Setup::Config)
        expect(Setup::Config).to receive(:new).and_return(config)
        expect(config).to receive(:validate!)
        
        cli = Setup::CLI.new(['validate'])
        cli.run
        
        output = stdout.string
        expect(output).to include('Setup - Validate Configuration')
        expect(output).to include('✓ Configuration is valid')
        expect(output).to include('✓ All migrations are valid')
      end
    end

    context 'unknown command' do
      it 'shows usage information' do
        cli = Setup::CLI.new(['unknown'])
        cli.run
        
        output = stdout.string
        expect(output).to include('Setup - Minimal Migration System')
        expect(output).to include('USAGE:')
        expect(output).to include('COMMANDS:')
      end
    end

    context 'no command' do
      it 'shows usage information' do
        cli = Setup::CLI.new([])
        cli.run
        
        output = stdout.string
        expect(output).to include('Setup - Minimal Migration System')
      end
    end
  end
end