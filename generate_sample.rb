# Script to generate a sample weather balloon observation file.
# Takes two parameters besides output filename: number of observatory batches and number of samples per batch.
# the product of these two inputs will result on the amount of observation samples in the file
# If these values are left empty, it uses 500 for both
#
# type: ruby generate_sample.rb --help for options
#
# Author: Carlos Barboza
# 
# Date: 2015-02-05

require 'optparse'
require 'sys/filesystem'
require './lib/weather_balloon'

OBSERVATORY_BATCHES = 500
SAMPLES_PER_BATCH   = 500
MAXIMUM_LINE_LENGTH = 40 # Bytes

def main(filename, options)
  options[:observatory_batches] = OBSERVATORY_BATCHES if options[:observatory_batches].nil?
  options[:samples_per_batch]   = SAMPLES_PER_BATCH if options[:samples_per_batch].nil?
 
  # check if there is enough disk space
  stat = Sys::Filesystem.stat("/")
  available = (stat.block_size * stat.blocks_available)/(1024*1024)
  required  = (options[:observatory_batches]*options[:samples_per_batch]*MAXIMUM_LINE_LENGTH)/(1024*1024)
  
  if required > available
    puts "Insuficient disk space to generate the required sample. #{available} MB available, #{required} MB required."
    exit 
  end

  file = File.open(filename, 'w')  
 
  obs = WeatherBalloon::Observation.new 

  observatory_batch_order = []

  # generates an array with an aleatory order of batches per observatory
  (1..options[:observatory_batches]).each do |i|
    observatory_batch_order << WeatherBalloon::OBSERVATORY_CODES.sample
  end

  observatory_batch_order.each do |o|
    (1..options[:samples_per_batch]).each do |i|
      # for every observatory generates samples_per_batch samples on the same time period, every sample is 1 minute apart from each other
      file.write(obs.sample(o)+"\n")
    end
  end

  file.close
end

##############################################
# Hash to handle the command line options
options = {}

# Class to handle the command line options and create the help banner
op = OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} output_filename [options]"
  opts.separator ""
  opts.separator "Specific options:"  

  opts.on('-b BATCHES', Integer, '--obs_batches', 'Total number of batches')                 { |v| options[:observatory_batches] = v }
  opts.on('-s SAMPLES', Integer, '--samples_per_batch', 'Number of samples for every batch') { |v| options[:samples_per_batch] = v }
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

# ARGV must have just one value, the file name, otherwise the help screen is shown.
# help screen is shown also in case of option -h
if options[:help] or ARGV.size!=1
  puts "\n"
  puts op.help
  puts "\n"
  exit  
else
  main(ARGV[0],options)  
end