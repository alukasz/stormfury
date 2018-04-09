defmodule Storm.SimulationsSupervisor do
  use DynamicSupervisor

  alias Storm.Simulation.SimulationSuperisor

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def start_child(simulation) do
    child_spec = {SimulationSuperisor, simulation}

    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  def terminate_child(%{id: id}) do
    pid = Registry.whereis_name({Storm.Registry.SimulationSupervisor, id})

    DynamicSupervisor.terminate_child(__MODULE__, pid)
  end

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
