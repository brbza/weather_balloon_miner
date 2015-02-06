# Module to solve the weather balloon problem of Ambiata's interview (https://github.com/ambiata/interview/blob/master/weather.md)
#
# Class Observation is used to parse an observation on the supplied format, validate it and convert it to different measurement units
# this class also has a method to generate random samples for an observatory
#
# Class ObservatoryStats is used to generate temperature statistics and flight distance per observatory. It also prints the the required
# statistics as specified on the print_options attribute.
#
# Author: Carlos Barboza
# 
# Date: 2015-02-05

require 'time'

module WeatherBalloon

  # Module Constants
  # Default Print Options
  PRINT_OPTIONS = { :min_temp=>true, :max_temp=>true, :mean_temp=>true, :num_obs=>true, :total_distance=>true }

  # Assuming that all observatories will be idendified by two letters ISO 3166-2 codes, considering just 10 codes for this excercise 
  OBSERVATORY_CODES = ["AR", "AU", "BR", "CA", "DE", "FR", "IT", "MX", "NZ", "US"]

  OBSERVATORY_UNITS = { "AU" => ["celsius"   ,"kilometers"], 
                        "US" => ["fahrenheit","miles"],
                        "FR" => ["kelvin"    ,"meters"] }

  # Date intervals for auto generation of observation samples
  START_TIME = Time.utc(2011, 1, 1, 0, 0, 0)
  END_TIME   = Time.utc(2015, 1,31,23,59,59)
  # Distance range for location coordinates in meters for auto generation of observation samples
  DIST_RANGE  = 0..5000000
  # Temperature range for auto generation of observation samples in Kelvin
  TEMP_RANGE  = 213..300

  
  class Observation
    attr_accessor :timestamp, :location, :temperature, :observatory

    def initialize (observation=nil)
      if observation!=nil
        result, error = validates(observation)
        raise ArgumentError.new(error) if result==false
      end
    end
    
    # generates an observation string on the same format as the used on the initialize method
    # distance and temperature units can be changed through the input parameters, if one or both are nil
    # the default units of the observatory are used.
    def to_s(dist_unit=nil, temp_unit=nil)
      raise ArgumentError.new("Invalid distance unit: #{dist_unit}")    unless dist_unit.nil? or ["kilometers","miles","meters"].include?(dist_unit)
      raise ArgumentError.new("Invalid temperature unit: #{temp_unit}") unless temp_unit.nil? or ["celsius","fahrenheit","kelvin"].include?(temp_unit)
      if dist_unit.nil? or temp_unit.nil?
        units = OBSERVATORY_UNITS[@observatory].nil? ? ["kelvin","kilometers"] : OBSERVATORY_UNITS[@observatory]
      end
      temp_unit = units[0] if temp_unit.nil?
      dist_unit = units[1] if dist_unit.nil?

      case dist_unit
      when "kilometers"  
        coords = "#{@location[0]/1000},#{@location[1]/1000}"
      when "miles" 
        coords = "#{@location[0]/1609},#{@location[1]/1609}"
      when "meters" 
        coords = "#{@location[0]},#{@location[1]}"
      end

      case temp_unit
      when "celsius"
        temp   = @temperature-273
      when "fahrenheit"
        temp   = ((@temperature*1.8)-459.67).ceil
      when "kelvin"
        temp   = @temperature 
      end     

      "#{@timestamp.strftime("%FT%R")}|#{coords}|#{temp}|#{@observatory}"
    end

    # Method used to generate samples from an observatory specified as a parameter, when attributes are empty it generates random values to it
    # if they are filled new values are assigned for timestamp, location and temperature. Timestamp is incremented by 60 seconds and a random 
    # margin is added to the temperature and location.
    # invalid lines are added based on the return of the rand function when compared to a threshold.
    def sample(observatory)
      raise ArgumentError.new("Invalid observatory code: #{observatory}") unless OBSERVATORY_CODES.include?(observatory)

      if @observatory.nil? or (@observatory!=observatory)
        @timestamp   = Time.at((END_TIME.to_f - START_TIME.to_f)*rand + START_TIME.to_f).utc
        @location    = [rand(DIST_RANGE), rand(DIST_RANGE)] 
        @temperature = rand(TEMP_RANGE)
        @observatory = observatory
      else
        @timestamp   = @timestamp + 60
        @location    = [@location[0] + rand(-500..500), @location[1] + rand(-500..500)] 
        @temperature = @temperature + rand(-1..1)    
      end
      rand<0.01 ? "invalid line" : self.to_s
    end    

    private
    # This method return two values, a boolean indicating the result of the validation and a string with the validation error if present
    # Also populate the class attributes in case of a well succeeded validation on Kelvin and meters
    def validates (data)
      # Split input line by pipe char and validates each field
      fields = data.split("|")
      # line must have 4 fields
      return false, "Incorrect number of arguments: #{fields.size} instead of 4!" if fields.size!=4
      # verifies timestamp size and format
      return false, "Incorrect timestamp string size: #{fields[0]}"               if fields[0].size!=16 
      begin
        DateTime.iso8601(fields[0])
      rescue ArgumentError
        return false, "Incorrect timestamp format: #{fields[0]}" 
      end
      # location must be represented by two natural numbers splited by comma
      return false, "Incorrect location format: #{fields[1]}"                     if fields[1].split(",").size!=2 or (fields[1].split(",")[0] =~ /^[0-9]+$/).nil? or (fields[1].split(",")[1] =~ /^[0-9]+$/).nil?
      # verifies if observatory code is valid
      return false, "Invalid observatory code: #{fields[3]}"                      unless OBSERVATORY_CODES.include?(fields[3])
      # verifies if temperature is a natual number for Kelvin input or a Integer for Celsius and Fahrenheit
      return false, "Incorrect temperature value (°K): #{fields[2]}"              if !["AU","US"].include?(fields[3]) and (fields[2] =~ /^[0-9]+$/).nil?
      return false, "Incorrect temperature value (°C): #{fields[2]}"              if fields[3]=="AU" and ((fields[2] =~ /^[-+]?[0-9]+$/).nil? or fields[2].to_i < -273)
      return false, "Incorrect temperature value (°F): #{fields[2]}"              if fields[3]=="US" and ((fields[2] =~ /^[-+]?[0-9]+$/).nil? or fields[2].to_i < -459)

      # Populate attributes and normalize to Kelvin and meters, no errors on validation
      @timestamp = DateTime.iso8601(fields[0])
      case fields[3]
      when "AU" # Celsius and Kilometers
        @location  = [fields[1].split(",")[0].to_i*1000, fields[1].split(",")[1].to_i*1000]
        @temperature = fields[2].to_i+273
      when "US" # Fahrenheit and Miles
        @location  = [fields[1].split(",")[0].to_i*1609, fields[1].split(",")[1].to_i*1609]
        @temperature = ((fields[2].to_i+459.67)*5.0/9.0).floor       
      when "FR" # Kelvin and Meters
        @location  = [fields[1].split(",")[0].to_i, fields[1].split(",")[1].to_i]
        @temperature = fields[2].to_i     
      else # Kelvin and Kilometers
        @location  = [fields[1].split(",")[0].to_i*1000, fields[1].split(",")[1].to_i*1000]
        @temperature = fields[2].to_i
      end
      @observatory = fields[3]

      return true, ""
    end
  end

  class ObservatoryStats
    attr_accessor :minimum_temp, :maximum_temp, :sum_temp, :num_observations, :total_distance, :last_coord, :print_options, :name

    OPTIONS_TO_STR = { :observatory =>    { :header => "Observatory Code",         :format => "%16s",   :attr => :name}, 
                       :min_temp =>       { :header => "Minimum Temperature (°C)", :format => "%24d",   :attr => :min_temp_c},             
                       :max_temp =>       { :header => "Maximum Temperature (°C)", :format => "%24d",   :attr => :max_temp_c},
                       :mean_temp =>      { :header => "Mean Temperature (°C)",    :format => "%21.1f", :attr => :mean_temp_c},
                       :num_obs =>        { :header => "Number of Observations",   :format => "%22d",   :attr => :num_observations},
                       :total_distance => { :header => "Total Distance (Km)",      :format => "%19.1f", :attr => :total_dist_km} }

    def initialize(name, print_options=PRINT_OPTIONS)
      @minimum_temp     = nil
      @maximum_temp     = nil
      @sum_temp         = 0
      @num_observations = 0
      @total_distance   = 0
      @last_coord       = nil
      @name             = name
      @print_options    = print_options
    end

    # method used to include an observation on the observatory statistics
    def add(observation)
      @minimum_temp = observation.temperature if @minimum_temp.nil? or (observation.temperature < @minimum_temp)
      @maximum_temp = observation.temperature if @maximum_temp.nil? or (observation.temperature > @maximum_temp)
      @sum_temp     = @sum_temp + observation.temperature
      @num_observations += 1
      if @last_coord!=nil
        # calculates the euclidian distance between this observation and the last point processed
        leap_distance = Math::sqrt((observation.location[0]-@last_coord[0])**2+(observation.location[1]-@last_coord[1])**2)
        @total_distance = @total_distance + leap_distance
      end    
      @last_coord = observation.location
    end

    # return mean temperature in celsius
    def mean_temp_c
      if num_observations > 0
        (@sum_temp.to_f/num_observations.to_f)-273
      else
        nil
      end
    end

    # return max temperature in celsius
    def max_temp_c
      if @maximum_temp.nil?
        nil
      else
        @maximum_temp-273
      end
    end  

    # return return max temperature in celsius
    def min_temp_c
      if @minimum_temp.nil?
        nil
      else
        @minimum_temp-273
      end
    end

    # return total distance in km
    def total_dist_km 
      @total_distance/1000
    end

    # method used to return the header of the to_s method considering @print_options flags
    def header
      header = []
      header << OPTIONS_TO_STR[:observatory][:header]
      
      @print_options.keys.each do |opt|
        header << OPTIONS_TO_STR[opt][:header]
      end

      header.join(" | ")
    end

    # method used to return the stats of the observatory considering @print_options flags
    def to_s
      data = []
      data << sprintf(OPTIONS_TO_STR[:observatory][:format] ,self.send(OPTIONS_TO_STR[:observatory][:attr]))

      @print_options.keys.each do |opt|
        data << sprintf(OPTIONS_TO_STR[opt][:format] ,self.send(OPTIONS_TO_STR[opt][:attr]))
      end

      data.join(" | ")      
    end
  end
end
