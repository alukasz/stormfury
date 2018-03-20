defmodule Storm.Simulation do
  alias Storm.SimulationServer
  alias Storm.SimulationsSupervisor

  def new(%Db.Simulation{} = simulation) do
    SimulationsSupervisor.start_child(simulation)
  end

  def get_ids(id, number) do
    GenServer.call(SimulationServer.name(id), {:get_ids, number})
  end
end
