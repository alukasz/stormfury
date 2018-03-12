defmodule Storm.Simulation do
  defstruct [
    :id,
    :url,
    :duration,
    :protocol_mod,
    transport_mod: Fury.Transport.WebSocket,
    sessions: []
  ]

  alias Storm.Simulation
  alias Storm.SimulationServer

  def new(%Simulation{} = simulation) do
    SimulationServer.start_link(simulation)
  end
end
