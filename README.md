# Time zone database tests

Elixir relies on third-party libraries to bring in time zone support.

Below are some available options:

* [`tz`](https://github.com/mathieuprog/tz)
* [`time_zone_info`](https://github.com/hrzndhrn/time_zone_info)
* [`tzdata`](https://github.com/lau/tzdata)
* [`zoneinfo`](https://github.com/smartrent/zoneinfo) -
  recommended for embedded devices

This repository allows to perform time zone operations on a huge set of predefined date times, for each of the libraries listed above, and compare their result.

## Generate the Java result set

Generate the result for Java by executing `java java/GenerateTzData.java`.

The result is written in `/files/output`.

## Generate the Elixir libraries result set

Execute the mix task to generate the result for the Elixir libraries (you can change the second argument to "files/input_far_future" if you want to switch the dataset):

```bash
mix tzdb.run tz "files/input"
mix tzdb.run time_zone_info "files/input"
mix tzdb.run zoneinfo "files/input"
mix tzdb.run tzdata "files/input"
```

The result is written in `/files/output`.

## Compare the results

### Correctness

Use your favorite diff tool to compare the result between the output of the libraries and Java. I consider the Java output the source of truth.

At the time of writing this,
* the output of Java, `tz` and `time_zone_info` is identical;
* `tzdata` generates a lot of wrong dates;
* `zoneinfo` generates wrong dates for some special time zones and for dates in the year 2038.

### Performance

The results from `mix run benchmark.exs` (removed Logging output):

```
Generated tzdb_test app
Operating System: macOS
CPU Information: Apple M3 Pro
Number of Available Cores: 11
Available memory: 36 GB
Elixir 1.17.2
Erlang 27.0.1
JIT enabled: true

Benchmark suite executing with the following configuration:
warmup: 2 s
time: 5 s
memory time: 0 ns
reduction time: 0 ns
parallel: 1
inputs: far future, standard
Estimated total run time: 1 min 10 s

Benchmarking java with input far future ...
Benchmarking java with input standard ...
Benchmarking time_zone_info with input far future ...
Benchmarking time_zone_info with input standard ...
Benchmarking tz with input far future ...
Benchmarking tz with input standard ...
Benchmarking tzdata with input far future ...
Benchmarking tzdata with input standard ...
Benchmarking zoneinfo with input far future ...
Benchmarking zoneinfo with input standard ...
Calculating statistics...
Formatting results...

##### With input far future #####
Name                     ips        average  deviation         median         99th %
java                    0.42         2.40 s     ±1.91%         2.39 s         2.45 s
time_zone_info        0.0695        14.39 s     ±0.00%        14.39 s        14.39 s
tz                    0.0259        38.61 s     ±0.00%        38.61 s        38.61 s
zoneinfo              0.0252        39.71 s     ±0.00%        39.71 s        39.71 s
tzdata                0.0220        45.41 s     ±0.00%        45.41 s        45.41 s

Comparison: 
java                    0.42
time_zone_info        0.0695 - 6.00x slower +11.99 s
tz                    0.0259 - 16.10x slower +36.21 s
zoneinfo              0.0252 - 16.56x slower +37.31 s
tzdata                0.0220 - 18.94x slower +43.02 s

##### With input standard #####
Name                     ips        average  deviation         median         99th %
java                   0.183         5.47 s     ±0.00%         5.47 s         5.47 s
zoneinfo              0.0416        24.04 s     ±0.00%        24.04 s        24.04 s
tz                    0.0408        24.51 s     ±0.00%        24.51 s        24.51 s
time_zone_info        0.0405        24.67 s     ±0.00%        24.67 s        24.67 s
tzdata               0.00771       129.72 s     ±0.00%       129.72 s       129.72 s

Comparison: 
java                   0.183
zoneinfo              0.0416 - 4.40x slower +18.57 s
tz                    0.0408 - 4.48x slower +19.04 s
time_zone_info        0.0405 - 4.51x slower +19.20 s
tzdata               0.00771 - 23.72x slower +124.25 s
```

## How does it work?

Predefined dates, against which time zone operations are tested, are located in `/files/input`.
Those dates include a lot of dates for which edge cases can be found (ambiguous times, gaps, etc.).

The input files list 51,112 dates.

 Example entry:
 ```text
America/Curacao;1912-02-11
```

For each of these dates, the program generates 96 date times. The first date time starts at midnight and is increased by a step of 15 minutes until 23:45.

This results in 4,906,752 (51,112 x 96) date times generated

Then for each date time, the following operations are performed:

1. Adds the time zone information to the naive date time
```elixir
DateTime.from_naive(naive_date_time, timezone)
```

2. Shifts the utc date time to the time zone
```elixir
naive_date_time
|> DateTime.from_naive!("Etc/UTC")
|> DateTime.shift_zone(timezone)
```

That makes for a total of 9,813,504 date times being generated.

The date times are written into files which can be compared between the different libraries (using a diff tool) to detect any errors and inconsistencies.
