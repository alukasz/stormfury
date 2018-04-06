defmodule Fury.Simulation.SimulationSuperisor do
  use Supervisor

  alias Fury.Simulation

  def start_link(%Simulation{} = simulation) do
    Supervisor.start_link(__MODULE__, simulation)
  end

  def init(simulation) do
    children = [
      {Fury.Simulation.SimulationServer, simulation}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
