# Randomly visit each slot several times near its start to determine how quickly it fills up.

require 'date'
require 'json'
require 'nokogiri'
require 'open-uri'

def get_params(uri)
  doc = Nokogiri::HTML uri.open

  params = {}
  doc.xpath('//form[@id="theform"]//input').each { |node| params[node['name']] = node['value'] }
  doc.xpath('//form[@id="theform"]//select').each { |node| params[node['name']] = 0 }
  params
end

def slot_time(slot)
  # e.g. 'Mon, March 1, 12 PM to  1:30 PM'
  /.*, (?<day>.*), (?<from>.*) +to +(?<to>.*)/ =~ slot
  [ Time.parse("#{day}, #{from}"), Time.parse("#{day}, #{to}") ]
end

def get_slot_state(time, uri, params)
  def offering_state(node)
    return :full unless node.xpath('td[2]/div[@class="offering-page-event-is-full"]').empty?
    return :open unless node.xpath('td[4]/a[@class="book-now-button"]').empty?
    return :na
  end

  params['show_date'] = time.strftime('%F')

  result = Net::HTTP.post_form(uri, params)

  begin
    offerings = Nokogiri::HTML JSON(result.body)['event_list_html']
  rescue JSON::ParserError
    File.write('errors/%s.txt' % Time.now.strftime('%F %k %M'), result.body)
    return {}
  end

  node = offerings.css('table#offering-page-select-events-table tr').find do |node|
    from, _ = slot_time(node.xpath('td[1]').text.strip)
    from.strftime('%H:%M') == time.strftime('%H:%M')
  end

  offering_state(node).to_s
end

def do_at(t)
  now = Time.now
  duration = t - now
  return unless duration > 0
  sleep duration
  yield now
end

def sleep_untill_next_day(t)
  duration = (t + 1).to_time - Time.now
  return unless duration > 0
  sleep duration
end

def random_visits(n, range)
  visits = Array.new
  range.each {|t| n.times { visits << t + rand }}
  visits.sort
end

offering_guid = '484c1a7ca09145419ef258eeb894c38f'
widget_guid   = '2224a8b95d0e4ca7bf20012ec34b8f3e'
uri = URI 'https://app.rockgympro.com/b/widget/?a=offering&offering_guid=%s&widget_guid=%s&random=6034454e7db83&iframeid=&mode=p' %
  [offering_guid, widget_guid]
query_uri = URI.join(uri, '/b/widget/?a=equery')

schedule = JSON.parse(File.read('analysis/schedule.json'))

loop do
  slots = {}
  params = get_params(uri)
  today = Date.today

  print today.strftime('%F ')


  schedule[today.wday].each do |t|
    available = Time.parse('%s %s' % [today.strftime('%F'), t])
    slot = Time.parse('%s %s' % [(today + 7).strftime('%F'), t])

    visits = {}

    begin
      random_visits(10, (-3 ... 3)).each do |offset|
        do_at(available + 60 * offset) do |now|
          state = get_slot_state(slot, query_uri, params)
          visits[Time.now.strftime('%F %H:%M:%S.%L')] = state
        end
      end
    rescue SocketError, OpenURI::HTTPError
      print 'x'
    else
      print '.'
    end

    next if visits.empty?

    slots[slot] = visits

    File.write('data/starts/%s.json' % today.strftime('%F'), slots.to_json) unless slots.empty?
  end
  print "\n"

  sleep_untill_next_day(today)
end
