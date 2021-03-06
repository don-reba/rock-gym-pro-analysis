# Take daily records generated by dl.rb and combine them into a single file.

require 'time'
require 'json'

def slot_time(slot)
  # e.g. 'Mon, March 1, 12 PM to  1:30 PM'
  /.*, (?<day>.*), (?<from>.*) +to +(?<to>.*)/ =~ slot
  [ Time.parse("#{day}, #{from}"), Time.parse("#{day}, #{to}") ]
end

samples = {}

Dir['data/????-??-??.json'].each do |path|
  /(?<day>....-..-..)/ =~ path
  puts day

  JSON.parse(File.read(path)).each do |t, days|
    t = Time.parse("#{day} #{t}")
    days.each do |d, slots|
      slots.each do |slot, status|
        from, _ = slot_time(slot)
        (samples[from.strftime('%F %H:%M')] ||= []) << [t.strftime('%F %H:%M'), status]
      end
    end
  end
end

samples.values.each {|statuses| statuses.sort!}

File.write('analysis/combined.json', JSON.pretty_generate(samples))
