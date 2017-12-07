require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

require 'yard'


def shell(*args)
  puts "running: #{args.join(' ')}"
  system(args.join(' '))
end

task :permissions do
  shell('rm -rf pkg/')
  shell("chmod -v o+r,g+r * */* */*/* */*/*/* */*/*/*/* */*/*/*/*/*")
  shell("find . -type d -exec chmod o+x,g+x {} \\;")
end

task :build => :permissions


YARD::Rake::YardocTask.new(:doc) do |t|
  t.files = %w(lib/**/*.rb exe/*.rb - README.md LICENSE.txt)
  t.options.unshift('--title', '"SimpleFeed — Fast and Scalable "write-time" Simple Feed for Social Networks, with a Redis-based default backend implementation."')
  t.after = ->() { exec('open doc/index.html') } if RUBY_PLATFORM =~ /darwin/
end


RSpec::Core::RakeTask.new(:spec)

task :default => :spec
