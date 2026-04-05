defmodule Elr.MixProject do
  use Mix.Project

  def project do
    [
      app: :elr,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      escript: [main_module: Elr.CLI],
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :inets, :ssl]
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.4"},
      {:igniter, "~> 0.6", only: [:dev, :test]}
    ]
  end
end
