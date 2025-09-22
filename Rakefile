require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task default: :spec

desc "Run tests"
task :test => :spec

desc "Run setup validation"
task :validate do
  sh "./setup validate"
end

desc "Run dry-run to test migrations"
task :dry_run do
  sh "./setup apply --dry-run"
end

desc "Run all checks (tests + validation + dry-run)"
task :check => [:spec, :validate, :dry_run]