defmodule Storm.Simulation.SimulationSuperisor do
  use Supervisor

  alias Storm.Simulation.SimulationServer
  alias Storm.Dispatcher.DispatcherServer

  def start_link(%Db.Simulation{} = simulation) do
    Supervisor.start_link(__MODULE__, simulation)
  end

  def init(%{id: id} = simulation) do
    children = [
      {DispatcherServer, id},
      {SimulationServer, simulation},
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
