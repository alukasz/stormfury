defmodule Storm.Simulation do
  alias Storm.Simulation
  alias Storm.SimulationServer
  alias Storm.SimulationsSupervisor

  defstruct [
    :id,
    :url,
    :duration,
    :protocol_mod,
    transport_mod: Fury.Transport.WebSocket,
    sessions: [],
    nodes: []
  ]

  def new(%Simulation{} = simulation) do
    SimulationsSupervisor.start_child(simulation)
  end

  def get_node(id) do
    GenServer.call(SimulationServer.name(id), :get_node)
  end
end
