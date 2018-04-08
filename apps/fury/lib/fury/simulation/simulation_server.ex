defmodule Fury.Simulation.SimulationServer do
  use GenServer, restart: :transient

  alias Fury.Session
  alias Fury.Simulation
  alias Fury.Simulation.Config
  alias Fury.SimulationsSupervisor

  def start_link(id) do
    GenServer.start_link(__MODULE__, id, name: name(id))
  end

  def init(id) do
    :pg2.join(Fury.group(id), self())

    {:ok, Config.simulation(id)}
  end

  def handle_call({:start_clients, session_id, ids}, _, state) do
    Session.start_clients(session_id, ids)

    {:reply, :ok, state}
  end
  def handle_call(:terminate, _, %{supervisor: supervisor} = state) do
    spawn fn ->
      SimulationsSupervisor.terminate_child(supervisor)
    end
    {:reply, :ok, state}
  end

  defp name(id) do
    Simulation.name(id)
  end
end
