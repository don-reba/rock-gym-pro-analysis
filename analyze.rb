require 'date'
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
  if secs > 0
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

samples = JSON.parse(File.read('analysis/combined.json'))
samples = samples.map do |slot, samples|
  [slot, samples.map {|t, status| [Time.parse(t), status.to_sym]}]
end

time_to_fill = {}

samples.each do |slot, samples|
  from, _ = slot_time(slot)
  available = available(from)

  first_t, _ = samples.first

  next unless first_t < available

  t, _ = samples.find {|_, status| status == :full}
  next unless t

  time_to_fill[slot] = t - available
end

time_to_fill.each do |slot, secs|
  puts '%s: %s' % [slot, humanize(secs)]
end
