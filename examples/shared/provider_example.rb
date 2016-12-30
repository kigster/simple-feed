$LOAD_PATH.unshift File.expand_path('../../../lib', __FILE__)

# Please set @feed in the enclosing context

raise ArgumentError, 'No @feed defined in the enclosing example' unless defined?(@feed)

require 'simplefeed'

@number_of_users = ARGV[0] ? ARGV[0].to_i : 1
@users           = Array.new(@number_of_users) { rand(200_000_000...800_000_000) }
@activity        = @feed.activity(@users)
@uid             = @users.first

include SimpleFeed::DSL

class Object
  def _v
    self.to_s.bold.red
  end
end

def p(*args)
  printf "%-40s %s\n", args[0].blue, args[1].bold.red
end

with_activity(@activity) do

  header "#{@activity.feed.provider_type} provider example"

  wipe

  store('value one') { p 'storing new value', 'value one' }
  store('value two') { p 'storing new value', 'value two' }
  store('value three') { p 'storing new value', 'value three' }

  hr

  total_count { |r| p 'total_count is now', "#{r[@uid]._v}" }
  unread_count { |r| p 'unread_count is now', "#{r[@uid]._v}" }

  header 'paginate(page: 1, per_page: 2)'
  paginate(page: 1, per_page: 2) { |r| puts r[@uid].map(&:to_color_s) }
  header 'paginate(page: 2, per_page: 2, reset_last_read: true)'
  paginate(page: 2, per_page: 2, reset_last_read: true) { |r| puts r[@uid].map(&:to_color_s) }

  hr

  total_count { |r| p 'total_count ', "#{r[@uid]._v}" }
  unread_count { |r| p 'unread_count ', "#{r[@uid]._v}" }

  hr
  store('value four') { p 'storing', 'value four' }

  color_dump

  header 'deleting'

  delete('value three') { p 'deleting', 'value three' }
  total_count { |r| p 'total_count ', "#{r[@uid]._v}" }
  unread_count { |r| p 'unread_count ', "#{r[@uid]._v}" }
  hr
  delete('value four') { p 'deleting', 'value four' }
  total_count { |r| p 'total_count ', "#{r[@uid]._v}" }
  unread_count { |r| p 'unread_count ', "#{r[@uid]._v}" }

end

