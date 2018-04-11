defmodule Storm.Simulation do
  alias Storm.SimulationsSupervisor

  defstruct [
    :id,
    :url,
    :duration,
    :protocol_mod,
    :transport_mod,
    sessions: [],
    clients_started: 0,
    supervisor_pid: nil,
    state_pid: nil
  ]

  def start(%Db.Simulation{} = simulation) do
    SimulationsSupervisor.start_child(simulation)
  end

  def terminate(%Db.Simulation{} = simulation) do
    SimulationsSupervisor.terminate_child(simulation)
  end

  def get_ids(id, number) do
    GenServer.call(name(id), {:get_ids, number})
  end

  def name(id) do
    {:via, Registry, {Storm.Registry.Simulation, id}}
  end
end
