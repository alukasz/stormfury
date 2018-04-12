defmodule Storm.Simulation.SimulationSupervisor do
  use Supervisor

  alias Storm.Simulation
  alias Storm.Simulation.Persistence
  alias Storm.Simulation.SimulationServer
  alias Storm.Dispatcher.DispatcherSupervisor

  def start_link(simulation_id) do
    Supervisor.start_link(__MODULE__, simulation_id)
  end

  def init(simulation_id) do
    case Persistence.get_simulation(simulation_id) do
      nil ->
        :ignore

      %Simulation{id: id, sessions: sessions} ->
        start_simulation(id, sessions)
    end
  end

  defp start_simulation(id, sessions) do
    children = [
      {SimulationServer, [id, self()]},
      {DispatcherSupervisor, [id, sessions]},
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
