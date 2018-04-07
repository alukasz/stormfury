defmodule Storm.Simulation do
  alias Storm.SimulationsSupervisor
  alias Storm.Simulation.SimulationServer

  def new(%Db.Simulation{} = simulation) do
    SimulationsSupervisor.start_child(simulation)
  end

  def get_ids(id, number) do
    GenServer.call(SimulationServer.name(id), {:get_ids, number})
  end
end
