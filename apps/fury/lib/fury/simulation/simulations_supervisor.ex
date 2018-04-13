defmodule Fury.Simulation.SimulationsSupervisor do
  use DynamicSupervisor

  alias Fury.Simulation.SimulationSupervisor

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def start_child(simulation_id, sessions) do
    opts = [simulation_id, sessions]

    DynamicSupervisor.start_child(__MODULE__, simulation_spec(opts))
  end

  def terminate_child(simulation_sup_pid) do
    DynamicSupervisor.terminate_child(__MODULE__, simulation_sup_pid)
  end

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  defp simulation_spec(opts) do
    {SimulationSupervisor, opts}
  end
end
