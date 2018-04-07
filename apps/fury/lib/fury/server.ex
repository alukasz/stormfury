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
    result = Simulation.start(simulation)

    {:reply, result, state}
  end
end