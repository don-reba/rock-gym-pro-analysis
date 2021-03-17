require 'date'
require 'nokogiri'
require 'json'
require 'time'

def available(from)
  # slots seem to open a minute early, by my clock
  from -= 60
  # simply subtracting a week would fail on dailight savings days
  d = (from.to_date - 7).strftime('%F')
  t = from.strftime('%T')
  Time.parse "#{d} #{t}"
end

def slot_time(slot)
  # e.g. 'Mon, March 1, 12 PM to  1:30 PM'
  /.*, (?<day>.*), (?<from>.*) +to +(?<to>.*)/ =~ slot
  [ Time.parse("#{day}, #{from}"), Time.parse("#{day}, #{to}") ]
end

def humanize(secs)
  if secs >= 1
    [[60, 'second'], [60, 'minute'], [24, 'hour'], [Float::INFINITY, 'day']].map do |count, name|
      if secs > 0
        secs, n = secs.divmod(count)
        suffix = n == 1 ? '' : 's'
        "#{n.to_i} #{name}#{suffix}" unless n.to_i == 0
      end
    end.compact.reverse.join(' ')
  else
    "#{secs} seconds"
  end
end

def set_fill(node, colour)
  style = node['style']
  node['style'] = style.gsub(/fill:[^;]*;/, 'fill:#%s;' % colour)
end

def cell_label(mins)
  [[60, 'm'], [24, 'h'], [7, 'd']].map do |count, name|
    mins, n = mins.divmod(count)
    "#{n}#{name}" if n > 0
  end .compact.reverse.join
end

def cell_colour(mins)
  return '0868ac' if mins <= 5
  return '43a2ca' if mins <= 15
  return '7bccc4' if mins <= 90
  return 'bae4bc' if mins <= 12 * 60
  return 'f0f9e8'
end

samples = JSON.parse(File.read('analysis/combined.json'))
samples = samples.map do |slot, samples|
  [slot, samples.map {|t, status| [Time.parse(t), status.to_sym]}]
end

time_to_fill = {}

samples.each do |slot, samples|
  available = available(Time.parse(slot))

  first_t, _ = samples.first

  next unless first_t < available

  t, _ = samples.find {|_, status| status == :full}
  next unless t

  time_to_fill[slot] = t - available
end

time_to_fill.each do |slot, secs|
  puts '%s: %s' % [slot, humanize(secs)]
end

doc = File.open('schedule.svg') {|f| Nokogiri::XML f}

doc.xpath("//svg:g[@inkscape:label='table']/svg:g/svg:g").each do |cell|
  set_fill(cell.at('./svg:rect'), 'FFFFFF')
  cell.at('./svg:text').content = ''
end

time_to_fill.each do |slot, secs|
  mins = (secs / 60).round

  from = Time.parse(slot)
  d = ['su', 'mo', 'tu', 'we', 'th', 'fr', 'sa'][from.strftime('%w').to_i]
  t = from.strftime('%H%M')

  text_node = doc.at("//svg:g[@inkscape:label='#{d}']/svg:g[@inkscape:label='#{t}']/svg:text")
  if text_node
    text_node.content = cell_label(mins)
  end

  rect_node = doc.at("//svg:g[@inkscape:label='#{d}']/svg:g[@inkscape:label='#{t}']/svg:rect")
  if rect_node
    set_fill(rect_node, cell_colour(mins))
  end
end

File.write('analysis/schedule.svg', doc.to_xml)
