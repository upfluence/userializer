require "bundler/gem_tasks"
require "rspec/core/rake_task"

version_file = "lib/userializer/version.rb"

task :update_version do
  version = (ENV['VERSION'] || `git describe --tag 2>/dev/null` || '').chomp.sub(/\Av/, '').then { |v| v.empty? ? '0.0.0' : v }
  original_version = File.binread(version_file)

  Bundler::GemHelper.gemspec.version = version
  at_exit { File.binwrite(version_file, original_version) }

  File.write(
    version_file,
    <<~RUBY
module USerializer
  VERSION = "#{version}"
end
    RUBY
  )
end

Rake::Task[:build].enhance([:update_version])

RSpec::Core::RakeTask.new(:spec)

task :default => :spec
