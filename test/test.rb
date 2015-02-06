# Simple tests to verify the basic functionalities of lib/weather_balloon.rb
#
# Author: Carlos Barboza
# 
# Date: 2015-02-05

require './lib/weather_balloon'

# Verifies if a created observation has the same parameters as the input used to create it
WeatherBalloon::OBSERVATORY_CODES.each do |observatory|
  obs=""
  # create a sample observation string
  while obs=="invalid line" or obs=="" do 
    obs = WeatherBalloon::Observation.new.sample("US")
  end
  # create an observation instance with the string generated above and save its string on obs2
  obs2 = WeatherBalloon::Observation.new(obs).to_s
  # verifies if both are the same
  if obs!=obs2 
    puts "failed to reproduce an observation for #{observatory}"
  else
    puts "succeeded to reproduce an observation for #{observatory}"
  end
end

# Verifies temperature and distance unit conversions
obs_km_celsius_str = "2014-12-31T13:44|10,5|243|AU"
obs = WeatherBalloon::Observation.new(obs_km_celsius_str)

if obs.to_s("miles","fahrenheit")!="2014-12-31T13:44|6,3|470|AU"
  puts "failed to convert units to miles, fahrenheit"
else
  puts "succeeded to convert units to miles, fahrenheit"
end

if obs.to_s("meters","kelvin")!="2014-12-31T13:44|10000,5000|516|AU"
  puts "failed to convert units to m, kelvin"
else
  puts "succeeded to convert units to m, kelvin"
end

obs_m_kelvin_str = "2014-12-31T13:44|10000,5000|516|FR"
obs = WeatherBalloon::Observation.new(obs_m_kelvin_str)

if obs.to_s("kilometers","celsius")!="2014-12-31T13:44|10,5|243|FR"
  puts "failed to convert units to km, celsius"
else
  puts "succeeded to convert units to km, celsius"
end

# Test ObservatoryStats class
obs_stats = WeatherBalloon::ObservatoryStats.new("test",)

(0..10).each do |i|
  obs_str = "2014-12-31T13:44|#{i},#{i}|#{i}|AU"
  obs = WeatherBalloon::Observation.new(obs_str)
  obs_stats.add(obs)
end

expected_output = "            test |                        0 |                       10 |                   5.0 |                     11 |                14.1"

if obs_stats.to_s!=expected_output
  puts "failed to calculate the stats of the observations"
else
  puts "succeeded to calculate the stats of the observations"
end  