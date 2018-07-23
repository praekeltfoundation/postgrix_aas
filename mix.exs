defmodule PostgrixAas.MixProject do
  use Mix.Project

  def project do
    [
      app: :postgrix_aas,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {PostgrixAas.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto, "~> 2.0"},
      {:postgrex, "~> 0.13"},
      {:poolboy, "~> 1.5.1"},
      {:ecto_network, "~> 0.6.0"},
      {:plug, "~> 1.4"},
      {:cowboy, "~> 2.3"},
      {:credo, "~> 0.9.1", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    [
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
