defmodule Fury.Simulation.SimulationSuperisor do
  use Supervisor, restart: :transient

  alias Fury.Simulation

  def start_link(%Simulation{} = simulation) do
    Supervisor.start_link(__MODULE__, simulation)
  end

  def init(%Simulation{id: id, sessions: sessions} = simulation) do
    children = [
      {Fury.Simulation.ConfigServer, %{simulation | supervisor: self()}},
      {Fury.Simulation.SimulationServer, id},
      {Fury.Session.SessionSupervisor, [id, sessions]},
      {Fury.Client.ClientSupervisor, id}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
