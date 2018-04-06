defmodule Fury.Simulation do
  alias Fury.Simulation
  alias Fury.SimulationsSupervisor

  defstruct [
    :id
  ]

  def start(%Simulation{} = simulation) do
    SimulationsSupervisor.start_child(simulation)
  end

  def name(%Simulation{id: id}) do
    {:via, Registry, {Fury.Registry.Simulation, id}}
  end
end
