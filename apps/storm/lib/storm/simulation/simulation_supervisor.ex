defmodule Storm.Simulation.SimulationSuperisor do
  use Supervisor

  alias Storm.Simulation.SimulationServer

  def start_link(%Db.Simulation{} = simulation) do
    Supervisor.start_link(__MODULE__, simulation, name: name(simulation))
  end

  def start_simulation(supervisor_pid, simulation_id, state_pid) do
    child_spec = {SimulationServer, [simulation_id, state_pid]}

    Supervisor.start_child(supervisor_pid, child_spec)
  end

  def init(%{id: id}) do
    children = [
      {StateServer, [id, self()]},
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def name(%{id: id}) do
    {:via, Registry, {Storm.Registry.SimulationSupervisor, id}}
  end
end
