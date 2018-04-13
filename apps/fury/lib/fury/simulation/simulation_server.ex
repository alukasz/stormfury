defmodule Fury.Simulation.SimulationServer do
  use GenServer

  alias Fury.Session
  alias Fury.Simulation.SimulationsSupervisor

  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init([id, supervisor_pid]) do
    Logger.metadata(simulation: id)
    Logger.info("Starting simulation")
    :pg2.join(Fury.group(id), self())

    {:ok, %{id: id, supervisor_pid: supervisor_pid}}
  end

  def handle_cast({:start_clients, session_id, ids}, state) do
    Session.start_clients(session_id, ids)

    {:noreply, state}
  end
  def handle_call(:terminate, _, %{supervisor_pid: supervisor_pid} = state) do
    Logger.info("Terminating simulation")
    spawn fn ->
      SimulationsSupervisor.terminate_child(supervisor_pid)
    end
    {:reply, :ok, state}
  end
end
