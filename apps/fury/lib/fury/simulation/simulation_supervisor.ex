defmodule Fury.Simulation.SimulationSuperisor do
  use Supervisor

  alias Fury.Simulation

  def start_link(%Simulation{} = simulation) do
    Supervisor.start_link(__MODULE__, simulation)
  end

  def init(%Simulation{id: id} = simulation) do
    children = [
      {Fury.Simulation.ConfigServer, simulation},
      {Fury.Simulation.SimulationServer, id},
      {Fury.Session.SessionSupervisor, id},
      {Fury.Session.ClientSupervisor, id}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
