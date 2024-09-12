defmodule Tzdb.MixProject do
  use Mix.Project

  def project do
    [
      app: :tzdb_test,
      version: "0.2.0",
      package: package(),
      elixir: "~> 1.14",
      description: "Testing Elixir time zone databases",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package do
    [
      licenses: ["Apache-2.0"],
      maintainers: ["Mathieu Decaffmeyer"],
      links: %{
        "GitHub" => "https://github.com/mathieuprog/tzdb_test"
      }
    ]
  end

  defp deps do
    [
      {:tz, "~> 0.28.1"},
      {:time_zone_info, "~> 0.7.5"},
      {:tzdata, "~> 1.1.2"},
      {:zoneinfo, "~> 0.1.8"},
      {:ex_doc, "~> 0.34", only: :dev},
      {:benchee, "~> 1.0", only: :dev}
    ]
  end
end
