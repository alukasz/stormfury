defmodule Fury.Simulation.SimulationServer do
  use GenServer

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

  defp name(id) do
    Simulation.name(id)
  end
end
