# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'simplefeed/version'

Gem::Specification.new do |spec|
  spec.name          = 'simple-feed'
  spec.version       = SimpleFeed::VERSION
  spec.authors       = ['Konstantin Gredeskoul']
  spec.email         = ['kigster@gmail.com']

  spec.summary       = %q{Create multiple types of social networking activity feeds with simple-feed gem, which uses a pluggable backend provider implementation, and ships with a Redis provider by default.}
  spec.description   = %q{This gem implements flexible time-ordered activity feeds commonly used withing social networking applications. As events occur, they are pushed into the Feed and distributed to all users that need to see the event. Upon the user visiting their "feed page", a pre-populated ordered list of events is returned by the library. Typically the data stored in the feed is a short-hand condensed variant of models, but it can also be a fully Marshalled objects, or JSON serializations. }
  spec.homepage      = 'https://github.com/kigster/simple-feed'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'base62-rb'
  spec.add_dependency 'hiredis'
  spec.add_dependency 'redis'
  spec.add_dependency 'hashie'
  spec.add_dependency 'connection_pool', '~> 2'
  spec.add_dependency 'activesupport'
  spec.add_dependency 'colored2'

  spec.add_development_dependency 'awesome_print'
  spec.add_development_dependency 'yard'
  spec.add_development_dependency 'simplecov', '~> 0.12'
  spec.add_development_dependency 'codeclimate-test-reporter', '~> 1.0'
  spec.add_development_dependency 'knjrbfw'
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.5'
  spec.add_development_dependency 'rspec-its'
end
