defmodule Fury.Simulation.SimulationServer do
  use GenServer

  alias Fury.Simulation

  defmodule State do
    defstruct [
      :id,
      :simulation
    ]

    def new(%Simulation{id: id} = simulation) do
      %State{
        id: id,
        simulation: simulation
      }
    end
  end

  def start_link(%Simulation{} = simulation) do
    GenServer.start_link(__MODULE__, simulation, name: name(simulation))
  end

  def init(simulation) do
    {:ok, State.new(simulation)}
  end

  defp name(simulation) do
    Simulation.name(simulation)
  end
end
