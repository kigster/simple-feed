require 'colored2'
require 'awesome_print'

AwesomePrint.force_colors = true
class Formatter
  class << self
    def header
      puts '——————————————————————————————————————————————————————————————————————————'.red
      puts 'COMMAND DESCRIPTION                                 LATENCY       RESULT   '.red
      puts '——————————————————————————————————————————————————————————————————————————'.red
      puts
    end

    def run
      t1       = Time.now.to_f
      result   = yield if block_given?
      t2       = Time.now.to_f
      duration = t2 - t1
      return duration, result
    end

    def print(message = nil, pp: false, user_id: nil, &block)
      duration, result = run(&block)
      if user_id
        user_id          = [user_id] if !user_id.is_a?(Array)
        user_id.each { |id| single_user_print(message, id, result, duration / user_id.size, pp) }
      else
        single_user_print(message, nil, result, duration, pp)
      end
      
    end

    def single_user_print(message, user_id, result, duration, pp)
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
