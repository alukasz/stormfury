defmodule Storm.SimulationSuperisor do
  use Supervisor

  def start_link(simulation) do
    Supervisor.start_link(__MODULE__, simulation)
  end

  def init(simulation) do
    children = [
      {Storm.SimulationServer, %{simulation | supervisor: self()}},
      Storm.SessionSupervisor
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
