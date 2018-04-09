use Mix.Config

config :logger, :console,
  metadata: [:application, :simulation]

if Mix.env == :test do
  config :logger, :console,
    level: :warn
end

import_config "../apps/*/config/config.exs"
