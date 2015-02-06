# Weather Balloon Miner

## Introduction

Set of scripts developed in Ruby to solve the [weather balloon] Ambiata's take home excercise.

## Setup Instructions

Code was developed and tested using ruby version 2.1.2 but should work without any issue on earlier versions. Besides default 
ruby libraries, gem [sys-filesystem] was used to calculate available disk space.

If you don't have this gem installed on your computer you can do it typing on the shell:

```sh
gem install sys-filesystem
```

or using bundle from project's root directory:

```sh
bundle install
```

## Scripts

### Generate Sample Observation File

To generate a sample file you should type on the shell:

```sh
ruby generate_sample.rb output_filename -b BATCHES -s SAMPLES
```

where:
- output_filename: desired name for the output file
- BATCHES: number of observatory batches to be filled on the file
- SAMPLES: number of observation samples per batch

The total amount of observations will be the product of BATCHES x SAMPLES. Batches are inserted in random order of observatories
and dates on the output file.

### Calculate Flight Statistics

To calculate the statistics of a observation file, you should run the following command on the shell:
```sh
ruby flight_stats.rb weather_balloon_data_file [options]
```
where options are used to select the desired statistics per observatory to display on the output, as:
- -i: minimum temperature
- -a: maxium temperature
- -e: mean temperature
- -n: number of observations
- -d: total flight distance

If no optios are supplied, all statistics are printed.

### Normalize Temperature and Distance Units of Observations

To normalize units of a observation file, type:

```sh
ruby normalize_observations.rb weather_balloon_data_file normalized_output_file [options]
```

where options are used to select the desired output units, as:
- -d: distance unit [ kelvin | celsius | fahrenheit ]
- -t: temperature unit [ meters | kilometers | miles ]

If no optios are supplied, defaults are kevin and meters.

## Additional files on the repository

- lib/weather_balloon.rb: module developed to handle the problem.
- test/test.rb: simple script to test basic functionalities of lib/weather_balloon.rb.

[weather balloon]:https://github.com/ambiata/interview/blob/master/weather.md
[sys-filesystem]:https://github.com/djberg96/sys-filesystem