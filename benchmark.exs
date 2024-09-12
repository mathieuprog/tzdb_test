benchmarks = %{
  "time_zone_info" => {
    fn input ->
      Benchmark.run(:time_zone_info, TimeZoneInfo.iana_version(), input)
    end,
    before_scenario: fn input ->
      Benchmark.start!(:time_zone_info)
      input
    end,
    after_scenario: fn _ ->
      Benchmark.stop!(:time_zone_info)
    end
  },
  "tz" => {
    fn input -> Benchmark.run(:tz, Tz.iana_version(), input) end,
    before_scenario: fn input ->
      Benchmark.start!(:tz)
      input
    end,
    after_scenario: fn _ ->
      Benchmark.stop!(:tz)
    end
  },
  "zoneinfo" => {
    fn input -> Benchmark.run(:tz, Benchmark.zoneifo_version(), input) end,
    before_scenario: fn input ->
      Benchmark.start!(:zoneinfo)
      input
    end,
    after_scenario: fn _ ->
      Benchmark.stop!(:zoneinfo)
    end
  },
  "tzdata" => {
    fn input -> Benchmark.run(:tzdata, Tzdata.tzdata_version(), input) end,
    before_scenario: fn input ->
      Benchmark.start!(:tzdata)
      input
    end,
    after_scenario: fn _ ->
      Benchmark.stop!(:tzdata)
    end
  }
}

benchmarks =
  if System.find_executable("java") do
    Map.merge(benchmarks, %{
      "java" => fn input ->
        System.cmd("java", ["java/GenerateTzData.java", input])
      end
    })
  else
    benchmarks
  end

Benchee.run(benchmarks,
  inputs: %{
    "standard" => "files/input",
    "far future" => "files/input_far_future"
  }
)
