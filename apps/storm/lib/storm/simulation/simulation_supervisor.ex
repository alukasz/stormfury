defmodule Storm.Simulation.SimulationSuperisor do
  use Supervisor

  alias Storm.Simulation.SimulationServer
  alias Storm.Dispatcher.DispatcherServer
  alias Storm.Launcher.LauncherSupervisor

  def start_link(%Db.Simulation{} = simulation) do
    Supervisor.start_link(__MODULE__, simulation, name: name(simulation))
  end

  def init(%{id: id, sessions: sessions} = simulation) do
    children = [
      {DispatcherServer, id},
      {LauncherSupervisor, sessions},
      {SimulationServer, simulation},
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def name(%{id: id}) do
    {:via, Registry, {Storm.Registry.SimulationSupervisor, id}}
  end
end
