defmodule Storm.Simulation.SimulationSuperisor do
  use Supervisor

  alias Storm.Simulation.LoadBalancerServer
  alias Storm.Simulation.SimulationServer

  def start_link(%Db.Simulation{} = simulation) do
    Supervisor.start_link(__MODULE__, simulation)
  end

  def init(simulation) do
    children = [
      {LoadBalancerServer, simulation},
      {SimulationServer, simulation},
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
