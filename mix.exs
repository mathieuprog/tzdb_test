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
      {:tz, "~> 0.26.4"},
      {:time_zone_info, "~> 0.7.0"},
      {:tzdata, "~> 1.1"},
      {:zoneinfo, "~> 0.1.7"}
    ]
  end
end
