defmodule Benchmark do
  # @input "files/input"
  # @input "files/input_far_future"
  @with_zone_abbr true

  def run(lib, version, input) do
    module = lib |> Atom.to_string() |> Macro.camelize()
    time_zone_db = Module.concat(module, TimeZoneDatabase)

    generate_files(
      time_zone_db,
      version,
      input,
      Path.join([File.cwd!(), "files/output", version, to_string(lib)])
    )
  end

  def start!(lib) do
    {:ok, _} = Application.ensure_all_started(lib)
    :ok
  end

  def stop!(lib) do
    :ok = Application.stop(lib)
    :ok
  end

  def zoneifo_version() do
    {:ok, version} = File.read("/usr/share/zoneinfo/+VERSION")
    String.trim(version)
  end

  defp date_time_to_string(dt) do
    dt_string = Calendar.strftime(dt, "%c")
    dt_string <> offset_to_string(dt.utc_offset + dt.std_offset)
  end

  defp offset_to_string(seconds) do
    is_negative = if(seconds < 0, do: true, else: false)
    seconds = if(is_negative, do: -1 * seconds, else: seconds)

    string =
      seconds
      |> :calendar.seconds_to_time()
      |> do_offset_to_string()
      |> List.to_string()

    if(is_negative, do: "-" <> string, else: "+" <> string)
  end

  defp do_offset_to_string({h, m, 0}), do: :io_lib.format("~2..0B:~2..0B", [h, m])
  defp do_offset_to_string({h, m, s}), do: :io_lib.format("~2..0B:~2..0B:~2..0B", [h, m, s])

  defp generate_files(time_zone_database, version, input, outputDir) do
    inputDir = Path.join([File.cwd!(), input])

    File.rm_rf!(outputDir)
    File.mkdir_p!(outputDir)

    File.ls!(inputDir)
    |> Enum.each(fn filename ->
      File.write!(Path.join(outputDir, filename), version <> "\n")

      File.stream!(Path.join(inputDir, filename))
      |> Stream.map(fn line ->
        [timezone, date] = String.split(line, ";", trim: true)

        timezone = String.trim(timezone)
        date = String.trim(date)

        {:ok, date} = Date.from_iso8601(date)
        {:ok, time} = Time.new(0, 0, 0)

        write_data(timezone, date, time, time_zone_database)
      end)
      |> Stream.into(File.stream!(Path.join(outputDir, filename), [:append]))
      |> Stream.run()
    end)
  end

  defp write_data(timezone, date, time, time_zone_database) do
    {:ok, naive_date_time} =
      NaiveDateTime.new(date.year, date.month, date.day, time.hour, time.minute, 0)

    output = [timezone, NaiveDateTime.to_iso8601(naive_date_time)]

    output =
      output ++
        try do
          case DateTime.from_naive(naive_date_time, timezone, time_zone_database) do
            {:ambiguous, dt1, dt2} ->
              ["ambiguous", date_time_to_string(dt1)] ++
                if(@with_zone_abbr, do: [dt1.zone_abbr], else: []) ++
                [date_time_to_string(dt2)] ++
                if(@with_zone_abbr, do: [dt2.zone_abbr], else: [])

            {:gap, dt1, dt2} ->
              ["gap", date_time_to_string(dt1)] ++
                if(@with_zone_abbr, do: [dt1.zone_abbr], else: []) ++
                [date_time_to_string(dt2)] ++
                if(@with_zone_abbr, do: [dt2.zone_abbr], else: [])

            {:ok, dt} ->
              ["ok", date_time_to_string(dt)] ++
                if(@with_zone_abbr, do: [dt.zone_abbr], else: [])
          end
        rescue
          error -> ["error", error.__struct__]
        end

    output =
      output ++
        try do
          {:ok, dt} =
            DateTime.from_naive!(naive_date_time, "Etc/UTC", time_zone_database)
            |> DateTime.shift_zone(timezone, time_zone_database)

          [date_time_to_string(dt)] ++
            if(@with_zone_abbr, do: [dt.zone_abbr], else: [])
        rescue
          error -> ["error", error.__struct__]
        end

    output = Enum.join(output, ";") <> "\n"

    if time.hour != 23 || time.minute != 45 do
      time = Time.add(time, 900)
      [output | write_data(timezone, date, time, time_zone_database)]
    else
      [output]
    end
  end
end
