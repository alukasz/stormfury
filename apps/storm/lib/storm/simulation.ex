defmodule Storm.Simulation do
  alias Storm.SimulationsSupervisor

  def start(%Db.Simulation{} = simulation) do
    SimulationsSupervisor.start_child(simulation)
  end

  def get_ids(id, number) do
    GenServer.call(name(id), {:get_ids, number})
  end

  def name(id) do
    {:via, Registry, {Storm.Registry.Simulation, id}}
  end
end
