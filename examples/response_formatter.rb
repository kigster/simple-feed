require 'colored2'
require 'awesome_print'

AwesomePrint.force_colors = true
class Formatter
  class << self
    def header
      line(1, 1) do
        puts 'COMMAND DESCRIPTION                                 LATENCY       RESULT   '.red
      end
    end

    def print_single_line
      puts '——————————————————————————————————————————————————————————————————————————'.red
    end

    def line(pre = nil, post = nil)
      pre.times { puts } if pre
      if block_given?
        print_single_line
        yield
        print_single_line
      else
        print_single_line
      end
      post.times { puts } if post
    end

    def with_timing(**opts, &block)
      opts.each_pair do |key, value|
        self.class.instance_eval do
          attr_accessor key
        end
        self.send("#{key}=".to_sym, value)
      end

      duration, * = run(&block)
      line(1) do
        printf '%s', "#{'Total Duration: '.upcase.white}#{'                                   '.cyan}" +
          sprintf("(%3.3f ms)\n", duration * 1000).yellow
      end
    end

    def run(&block)
      t1           = Time.now.to_f
      result       = instance_eval(&block)
      t2           = Time.now.to_f
      duration     = t2 - t1
      return duration, result
    end

    def p(message = nil, pp: false, &block)
      duration, result = run(&block)
      if self.ua && ua.is_a?(SimpleFeed::MultiUserActivity)
        ua.each { |id| single_user_print(message, id, result, duration / ua.size, pp) }
      else
        raise ArgumentError, 'Do what? ' + message
      end
    end

    alias_method :%, :p

    def single_user_print(message, user_id, result, duration, pp)
      # self.user_id = user_id
      message.gsub!(/%user%/, "for user #{user_id.to_s.green.bold}") if user_id
      message = message.split(' ').map { |w| w=~ /^#/ ? w.magenta : w.blue }.join(' ')
      printf '%-140s (%3.3f ms) %s', message, duration*1000, ' ⇨  '.cyan
      result = result[user_id] if result.respond_to?(:has_user?) && result.has_user?(user_id)
      if pp then
        printf "\n"
        ap(result)
      else
        puts(result.inspect.yellow)
      end
    end
  end
end
