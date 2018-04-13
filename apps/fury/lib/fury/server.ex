defmodule Fury.Server do
  use GenServer

  alias Fury.Simulation

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    {:ok, %{}}
  end

  def handle_call({:start_simulation, simulation_id, sessions}, _, state) do
    create_group(simulation_id)
    result = Simulation.start(simulation_id, sessions)

    {:reply, result, state}
  end

  defp create_group(id) do
    :pg2.create(Fury.group(id))
  end
end
