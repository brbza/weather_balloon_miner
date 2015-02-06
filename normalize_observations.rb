# Script to normalize the distance and temperature units of a weather balloon observation file.
#
# Takes two parameters besides input and output filenames: temperature and distance units.
# If these values are empty it uses meters and kelvin as default
#
# type: ruby generate_sample.rb --help for options
#
# Author: Carlos Barboza
# 
# Date: 2015-02-05

require 'optparse'
require 'sys/filesystem'
require './lib/weather_balloon'

def main(input_file, output_file, options)
  # If options are nil assign default units: meters and kelvin
  options[:distance_unit]    = "meters" if options[:distance_unit].nil?
  options[:temperature_unit] = "kelvin" if options[:temperature_unit].nil?  

  # check if there is enough disk space to write the output normalized file
  file_size = File.open(input_file).size  
  stat = Sys::Filesystem.stat("/")
  available = (stat.block_size * stat.blocks_available)

  if file_size > available
    puts "Insuficient disk space to generate the normalized file. #{available} MB available, #{file_size} MB required."
    exit 
  end

  outfile = File.open(output_file, 'w')  
 
  # Read the input file line by line, parse the observation and write it on the destination file with the requested units
  File.open(input_file).each_line do |line|
    begin
      # parse the observation
      obs = WeatherBalloon::Observation.new(line.chomp)
      # save it with the requested units on the destination file
      outfile.write(obs.to_s(options[:distance_unit],options[:temperature_unit])+"\n")
    rescue ArgumentError => e
      puts e.message if options[:verbose]
    end  
  end
  outfile.close
end

##############################################
# Hash to handle the command line options
options = {}

# Class to handle the command line options and create the help banner
op = OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} weather_balloon_data_file normalized_output_file [options]"
  opts.separator ""
  opts.separator "Specific options:"  

  opts.on('-d', '--distance_unit [ meters | kilometers | miles]', String, 'Normalized distance unit') { |v| options[:distance_unit] = v }
  opts.on('-t', '--temperature_unit [ kelvin | celsius | fahrenheit ]', String, 'Normalized temperature unit') { |v| options[:temperature_unit] = v }
  opts.on('-v', '--verbose',        'Verbose output of parsing errors') { |v| options[:verbose] = v }
  opts.on('-h', '--help',           'Show this message')                { |v| options[:help] = v }
end

# In case of a unknown option an exception is raised and the help banner is presented
# After the parse, options are removed from ARGV
begin
  op.parse!(ARGV)
rescue Exception => e
  puts "\n#{e.message}"
  puts "\n"
  puts op.help
  puts "\n"
  exit
end

if !["meters", "kilometers", "miles"].include?(options[:distance_unit]) 
  puts "\nInvalid distance unit: #{options[:distance_unit]}"
  puts "\n"
  puts op.help
  puts "\n"
  exit
end

if !["kelvin", "celsius", "fahrenheit"].include?(options[:temperature_unit])
  puts "\nInvalid distance unit: #{options[:temperature_unit]}"
  puts "\n"
  puts op.help
  puts "\n"
  exit  
end

# ARGV must have just one value, the file name, otherwise the help screen is shown.
# help screen is shown also in case of option -h
if options[:help] or ARGV.size!=2
  puts "\n"
  puts op.help
  puts "\n"
  exit  
else
  main(ARGV[0],ARGV[1],options)  
end