defmodule Fury.Server do
  use GenServer

  alias Fury.Simulation

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    {:ok, %{}}
  end

  def handle_call({:start_simulation, %Simulation{} = simulation}, _, state) do
    create_group(simulation)
    result = Simulation.start(simulation)

    {:reply, result, state}
  end

  defp create_group(%{id: id} = simulation) do
    :pg2.create(Fury.group(id))
  end
end
