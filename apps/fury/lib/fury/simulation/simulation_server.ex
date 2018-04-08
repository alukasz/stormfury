defmodule Fury.Simulation.SimulationServer do
  use GenServer

  alias Fury.Session
  alias Fury.Simulation
  alias Fury.Simulation.Config

  defmodule State do
    defstruct [
      :id,
      :simulation
    ]

    def new(id) do
      %State{
        id: id,
        simulation: Config.simulation(id)
      }
    end
  end

  def start_link(id) do
    GenServer.start_link(__MODULE__, id, name: name(id))
  end

  def init(id) do
    :pg2.join(Fury.group(id), self())

    {:ok, State.new(id)}
  end

  def handle_call({:start_clients, session_id, ids}, _, state) do
    Session.start_clients(session_id, ids)

    {:reply, :ok, state}
  end

  defp name(id) do
    Simulation.name(id)
  end
end
