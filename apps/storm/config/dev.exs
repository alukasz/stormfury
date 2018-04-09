use Mix.Config

config :storm,
  fury_bridge: Storm.Fury,
  nodes: [
    :"fury@127.0.0.1",
    :"fury1@127.0.0.1",
    :"fury2@127.0.0.1",
    :"fury3@127.0.0.1"
  ]
