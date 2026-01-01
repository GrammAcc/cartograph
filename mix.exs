defmodule Cartograph.MixProject do
  use Mix.Project

  def project do
    [
      app: :cartograph,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "URI-Based Navigation for Phoenix LiveView",
      name: "Cartograph",
      package: package(),
      docs: docs(),
    ]
  end

  defp docs do
    [
      source_url: "https://github.com/GrammAcc/cartograph",
      main: "readme",
      extras: ["README.md"],
    ]
  end

  defp package do
    [
      maintainers: ["Dalton Lang"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/GrammAcc/cartograph"},
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix_live_view, "~> 1.1"},
      {:freedom_formatter, ">= 2.1.3", only: [:dev, :test]},
      {:ex_doc, "~> 0.39", only: [:dev], runtime: false},
    ]
  end
end
