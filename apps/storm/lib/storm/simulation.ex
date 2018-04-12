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
    sessions_pids: [],
    dispatcher_pid: nil,
    supervisor_pid: nil,
  ]

  def start(simulation_id) do
    SimulationsSupervisor.start_child(simulation_id)
  end

  def terminate(supervisor_pid) do
    SimulationsSupervisor.terminate_child(supervisor_pid)
  end

  def set_dispatcher(id) do
    GenServer.call(name(id), :set_dispatcher)
  end

  def get_session(id, session_id) do
    GenServer.call(name(id), {:get_session, session_id})
  end

  def get_ids(id, number) do
    GenServer.call(name(id), {:get_ids, number})
  end

  def name(id) do
    {:via, Registry, {Storm.Registry.Simulation, id}}
  end
end
