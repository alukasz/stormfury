use Mix.Config

config :storm, :host, System.get_env("STORMFURY_HOST") ||
  raise "STORMFURY_HOST environment variable must be set!"

import_config "#{Mix.env}.exs"
