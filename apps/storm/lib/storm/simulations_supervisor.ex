defmodule Storm.SimulationsSupervisor do
  use DynamicSupervisor

  alias Storm.Simulation.SimulationSupervisor

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def start_child(simulation_id) do
    child_spec = {SimulationSupervisor, simulation_id}

    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  def terminate_child(child_pid) do
    DynamicSupervisor.terminate_child(__MODULE__, child_pid)
  end

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
