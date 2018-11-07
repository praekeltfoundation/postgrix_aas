defmodule PostgrixAas.MixProject do
  use Mix.Project

  def project do
    [
      app: :postgrix_aas,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      test_coverage: [tool: ExCoveralls]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      env: [endpoint: "http://localhost"],
      mod: {PostgrixAas.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto, "~> 2.0"},
      {:postgrex, "~> 0.13"},
      {:ecto_network, "~> 0.6.0"},
      {:plug, "~> 1.7"},
      {:plug_cowboy, "~> 2.0"},
      {:cowboy, "~> 2.3"},
      {:vaultix, "~> 0.9"},
      {:credo, "~> 0.9.1", only: [:test, :dev], runtime: false},
      {:jason, "~> 1.1"},
      {:excoveralls, "~> 0.5.7", only: :test},
      {:bypass, "~> 0.9", only: [:dev, :test]}
    ]
  end

  defp aliases do
    [
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
