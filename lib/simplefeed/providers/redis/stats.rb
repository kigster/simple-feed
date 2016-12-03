require 'redis'
require 'hashie/mash'
require 'yaml'

module SimpleFeed
  module Providers
    module Redis
      class Stats

        attr_accessor :redis

        def initialize(redis)
          self.redis = redis
        end

        def info
          self.class.destringify(redis.info)
        end

        def boot_info
          self.class.boot_info
        end

        @boot_info = nil

        class << self
          attr_accessor :boot_info

          # Converts strings values of a hash into floats or integers,
          # if the string matches a corresponding pattern.
          def destringify(hash)
            db_hash = {}
            hash.each_pair do |key, value|
              if key =~ /^db\d+$/
                h = {}
                value.split(/,/).each do |word|
                  *words      = word.split(/=/)
                  h[words[0]] = words[1]
                end
                destringify(h)
                db_hash[key.gsub(/^db/, '').to_i] = h
                hash.delete(key)
              else
                hash[key] =
                  if value =~ /^-?\d+$/
                    value.to_i
                  elsif value =~ /^-?\d*\.\d+$/
                    value.to_f
                  else
                    value
                  end
              end
            end
            hash[:dbstats] = db_hash unless db_hash.empty?
            Hashie::Mash.new(hash)
          end

          def load_boot_stats!
            @boot_info ||= destringify(YAML.load(File.open(File.expand_path('../boot_info.yml', __FILE__))))
          end

        end

        load_boot_stats!

        boot_info.keys.each do |key|
          unless key.to_s =~ /^db[0-9]+/

            define_method(key.to_sym) do
              info[key]
            end

            define_method("#{key}_at_boot".to_sym) do
              boot_info[key]
            end

            define_method("#{key}_since_boot".to_sym) do
              info[key] - boot_info[key]
            end
          end
        end
      end
    end
  end
end
