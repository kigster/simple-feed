#!/usr/bin/env ruby
# frozen_string_literal: true

require 'guard/rspec'

guard :rspec,
      version:        3,
      cmd:            'bundle exec rspec',
      bundler:        true,
      all_after_pass: false,
      all_on_start:   false,
      keep_failed:    false do
  watch(/.*\.gemspec/) { 'spec' }
  watch(%r{^lib/(.+)\.rb$}) { 'spec' }
  watch(%r{^spec/.+_spec\.rb$})
  watch('spec/spec_helper.rb') { 'spec' }
  watch(%r{spec/support/.*}) { 'spec' }
end
