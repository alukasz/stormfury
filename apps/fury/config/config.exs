use Mix.Config

config :fury, storm_node: :"nonode@nohost"

import_config "#{Mix.env}.exs"
