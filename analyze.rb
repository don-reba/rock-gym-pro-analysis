require 'json'
require 'time'

class Numeric
  def minutes
    60 * self
  end

  def hours
    60 * minutes
  end

  def days
    24 * hours
  end
end

def slot_time(slot)
  # e.g. 'Mon, March 1, 12 PM to  1:30 PM'
  /.*, (?<day>.*), (?<from>.*) +to +(?<to>.*)/ =~ slot
  [ Time.parse("#{day}, #{from}"), Time.parse("#{day}, #{to}") ]
end

def humanize(secs)
  [[60, :second], [60, :minute], [24, :hour], [Float::INFINITY, :day]].map do |count, name|
    if secs > 0
      secs, n = secs.divmod(count)
      suffix = n == 1 ? '' : 's'
      "#{n.to_i} #{name}#{suffix}" unless n.to_i == 0
    end
  end.compact.reverse.join(' ')
end

samples = JSON.parse(File.read('analysis/combined.json'))
samples = samples.map do |slot, samples|
  [slot, samples.map {|t, status| [Time.parse(t), status.to_sym]}]
end

time_to_fill = {}

samples.each do |slot, samples|
  next if samples.empty?
  next if samples[0][1] == :full

  from, _ = slot_time(slot)
  available = from - 7.days

  t, _ = samples.find {|_, status| status == :full}
  next unless t

  from, _ = slot_time(slot)
  t + 7.days - from
end

time_to_fill.each do |slot, secs|
  puts '%s: %s' % [slot, humanize(secs)]
end
