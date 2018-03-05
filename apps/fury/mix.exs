defmodule Fury.MixProject do
  use Mix.Project

  def project do
    [
      app: :fury,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Fury.Application, []}
    ]
  end

  defp deps do
    [
      {:poison, "~> 3.1"},
      {:websocket_client, github: "sanmiguel/websocket_client", tag: "1.3.0"}
    ]
  end
end
