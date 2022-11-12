defmodule Tzdb.MixProject do
  use Mix.Project

  def project do
    [
      app: :tzdb_test,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:tz, "~> 0.24.0"},
      {:time_zone_info, "~> 0.6.4"},
      {:tzdata, "~> 1.1"},
      {:zoneinfo, "~> 0.1.5"}
    ]
  end
end
