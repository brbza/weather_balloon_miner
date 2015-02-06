# Script to calculate the flight statistics of a weather balloon per relayed observatory.
#
# type: ruby flight_stats.rb --help for options
#
# Author: Carlos Barboza
# 
# Date: 2015-02-05

require 'optparse'
require 'sys/filesystem'
require './lib/weather_balloon'

# Main function to process the file with supplied options
def main(filename,options)
  # Creates a hash to store the statistics per observatory
  flight_stats = Hash.new

  WeatherBalloon::OBSERVATORY_CODES.each do |o|
    # Class ObservatoryStats used to keep, add and present observatory stats.
    flight_stats[o] = WeatherBalloon::ObservatoryStats.new(o, options)
  end

  # check file size and whether we have disk space to create a tmp sorted file
  file_size = File.open(filename).size
  stat = Sys::Filesystem.stat("/")
  available = (stat.block_size * stat.blocks_available)  

  if file_size > available
    puts "There is not enough disk space to create a sorted temporary file."
    exit
  end

  # sort file using linux 'sort' command to a tmp file since the first characters are the date/time and are text sortable
  # this way observations will be added to the correspondent ObseravtoryStats instance in chronological order
  # allowing distance calculation.
  
  sort_result = `sort #{filename} > #{filename}.tmp`

  if sort_result != ""
    puts "Error while sorting the file: #{sort_result}"
    exit
  end

  # Read the sorted file by line to not overload memory and populate the statistics
  file = File.open(filename+".tmp")

  file.each_line do |line|
    begin
      # class Observation used to parse, validate and convert measurement units of observations
      obs = WeatherBalloon::Observation.new(line.chomp)
      # If observation is valid add it to the observatory stats
      flight_stats[obs.observatory].add(obs)
    rescue ArgumentError => e
      puts "Invalid data at line #{file.lineno} will be discarded: #{e.message} => #{line}" if options[:verbose]
    end  
  end

  file.close
  
  # Print the table header
  if !flight_stats.empty?  
    puts flight_stats.values.first.header
  end

  # Print the statistics for every observatory
  flight_stats.each do |k, o|
    puts o.to_s
  end

  # Delete temporary file
  rm_result = `rm #{filename}.tmp`

  if rm_result != ""
    puts "Error deleting sorted file: #{rm_result}"
  end  
end

################################################
# Hash to handle the command line options
options = {}

# Class to handle the command line options and create the help banner
op = OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} weather_balloon_data_file [options]"
  opts.separator ""
  opts.separator "Specific options:"  

  opts.on('-i', '--min_temp',       'Minimum Temperature')              { |v| options[:min_temp] = v }
  opts.on('-a', '--max_temp',       'Maximum Temperature')              { |v| options[:max_temp] = v }
  opts.on('-e', '--mean_temp',      'Mean Temperature')                 { |v| options[:mean_temp] = v }
  opts.on('-n', '--num_obs',        'Number of Observations')           { |v| options[:num_obs] = v }
  opts.on('-d', '--total_distance', 'Total Flight Distance')            { |v| options[:total_distance] = v }
  opts.on('-v', '--verbose',        'Verbose output of parsing errors') { |v| options[:verbose] = v }
  opts.on('-h', '--help',           'Show this message')                { |v| options[:help] = v }
end

# In case of a unknown option an exception is raised and the help banner is presented
# After the parse, options are removed from ARGV
begin
  op.parse!(ARGV)
rescue OptionParser::InvalidOption => e
  puts "\n#{e.message}"
  puts "\n"
  puts op.help
  puts "\n"
  exit
end

# ARGV must have just one value, the file name, otherwise the help screen is shown.
# help screen is shown also in case of option -h
if options[:help] or ARGV.size!=1
  puts "\n"
  puts op.help
  puts "\n"
  exit  
else
  # If none options are supplied on the command line assumes to use all presentation options, verbose set to false.
  options = WeatherBalloon::PRINT_OPTIONS if options.empty?
  main(ARGV[0],options)  
end