require 'time'
require 'json'
require 'set'

schedule = Array.new(7) { Set.new }

samples = JSON.parse(File.read('analysis/combined.json'))
samples = samples.keys.map do |slot|
  from = Time.parse(slot)
  schedule[from.wday] << from.strftime('%H:%M')
end

schedule = schedule.map(&:to_a)

File.write('analysis/schedule.json', JSON.pretty_generate(schedule))
