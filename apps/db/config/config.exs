use Mix.Config


config :mnesia, :dir, to_charlist("./apps/db/priv/mnesia/#{Mix.env}")
