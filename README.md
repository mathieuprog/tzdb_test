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

Generate the result for Java by executing `GenerateTzData.java` in `/java`.

The result is written in `/files/output`.

## Generate the Elixir libraries result set

Execute the mix task to generate the result for the Elixir libraries:

```bash
mix tzdb.run tz
mix tzdb.run time_zone_info
mix tzdb.run zoneinfo
mix tzdb.run tzdata
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

Time spent generating the result is logged in the console, giving some idea of the difference in terms of performance.

The time taken for each library to generate the output on my system are:
*  ~50 seconds for `tz`
*  ~50 seconds for `time_zone_info`
*  ~80 seconds for `zoneinfo`
*  ~160 seconds for `tzdata`

System used:
* Operating system: macOS
* CPU: Apple M2
* Available cores: 8
* Available memory: 16 GB
* Elixir version: 1.14.1
* Erlang version: 25.1.2

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
