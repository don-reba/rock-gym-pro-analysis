require 'time'
require 'json'

samples = {}

Dir['data/????-??-??.json'].each do |path|
  /(?<day>....-..-..)/ =~ path
  puts day

  JSON.parse(File.read(path)).each do |t, days|
    t = Time.parse("#{day} #{t}")
    days.each do |d, slots|
      slots.each do |slot, status|
        (samples[slot] ||= []) << [t.strftime('%F %H:%M'), status]
      end
    end
  end
end

samples.values.each {|statuses| statuses.sort!}

File.write('analysis/combined.json', JSON.pretty_generate(samples))
