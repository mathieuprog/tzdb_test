defmodule Mix.Tasks.Tzdb.Run do
  use Mix.Task

  def run([lib, input]) do
    run_benchmark(lib, input)
  end

  def run(_) do
    Mix.raise(
      "command requires two argument: the name of the library to generate data for (tz, time_zone_info, zoneinfo, tzdata) and an input directory"
    )
  end

  defp run_benchmark("tz", input), do: Benchmark.run(:tz, Tz.iana_version(), input)

  defp run_benchmark("time_zone_info", input),
    do: Benchmark.run(:time_zone_info, TimeZoneInfo.iana_version(), input)

  defp run_benchmark("zoneinfo", input),
    do: Benchmark.run(:zoneinfo, Benchmark.zoneifo_version(), input)

  defp run_benchmark("tzdata", input),
    do: Benchmark.run(:tzdata, Tzdata.tzdata_version(), input)
end
