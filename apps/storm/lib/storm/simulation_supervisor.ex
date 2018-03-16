defmodule Storm.SimulationSuperisor do
  use Supervisor

  alias Storm.Simulation

  def start_link(%Simulation{} = simulation) do
    Supervisor.start_link(__MODULE__, simulation)
  end

  def init(simulation) do
    children = [
      {Storm.SessionSupervisor, simulation},
      {Storm.Simulation.LoadBalancerServer, simulation},
      {Storm.SimulationServer, simulation},
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
