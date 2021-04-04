require 'time'
require 'json'

def time_available(t)
  Time.parse('%s %s' % [t.to_date - 7, t.strftime('%T')])
end

slots = Dir['data/starts/????-??-??.json'].
  map {|path| JSON.parse File.read path}.
  inject(&:merge).
  map {|slot, visits| [
    Time.parse(slot),
    visits.map {|t, state| [Time.parse(t), state.to_sym]} .to_h]}.
  to_h

# get the interesting slots
fast = slots.filter {|_, v| v.values & [:na, :full] == [:na, :full]}

puts "#{fast.count}/#{slots.count} slots filled up quickly"

# print ranges
File.open('analysis/starts.csv', 'w') do |f|
  f.puts 'begin,end'
  fast.each do |slot, visits| 
    avail = time_available(slot)
    i = visits.values.index(:full)
    min = visits.keys[i - 1] - avail
    max = visits.keys[i] - avail
    f.puts '%f,%f' % [min, max]
  end
end
