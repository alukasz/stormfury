use Mix.Config

config :storm,
  fury_bridge: Storm.Mock.Fury,
  nodes: Storm.Mock.Nodes
