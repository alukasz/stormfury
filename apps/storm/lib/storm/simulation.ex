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
  alias Storm.SimulationsSupervisor

  def new(%Simulation{} = simulation) do
    SimulationsSupervisor.start_child(simulation)
  end
end
