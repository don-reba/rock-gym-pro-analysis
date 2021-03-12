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

def get_offerings(day, uri, params)
  def offering_state(node)
    return :full unless node.xpath('td[2]/div[@class="offering-page-event-is-full"]').empty?
    return :open unless node.xpath('td[4]/a[@class="book-now-button"]').empty?
    return :na
  end

  params['show_date'] = day

  result = Net::HTTP.post_form(uri, params)

  begin
    offerings = Nokogiri::HTML JSON(result.body)['event_list_html']
  rescue JSON::ParserError
    File.write('errors/%s.txt' % Time.now.strftime('%F %T'), result.body)
    return {}
  end

  slots = {}
  offerings.css('table#offering-page-select-events-table tr').each do |node|
    slots[node.xpath('td[1]').text.strip] = offering_state(node).to_s
  end

  slots
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

offering_guid = '484c1a7ca09145419ef258eeb894c38f'
widget_guid   = '2224a8b95d0e4ca7bf20012ec34b8f3e'
uri = URI 'https://app.rockgympro.com/b/widget/?a=offering&offering_guid=%s&widget_guid=%s&random=6034454e7db83&iframeid=&mode=p' %
  [offering_guid, widget_guid]
query_uri = URI.join(uri, '/b/widget/?a=equery')

loop do
  data = {}
  params = get_params(uri)
  today = Date.today

  24.times do |h| # each hour
    print '%02d ' % h
    60.times do |m| # each minute
      begin
        do_at(Time.parse('%02d:%02d' % [h, m])) do |now|
          minute_data = {}
          8.times do |n|
            day = (today + n).strftime('%F')
            minute_data[day] = get_offerings(day, query_uri, params)
          end
          data[now.strftime('%H:%M')] = minute_data
        end
      rescue SocketError
        print 'x'
      else
        print '.'
      end
    end
    File.write('data/%s.json' % today.strftime('%F'), data.to_json)
    print "\n"
  end

  sleep_untill_next_day(today)
end

