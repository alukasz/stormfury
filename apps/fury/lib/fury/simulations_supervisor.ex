defmodule Fury.SimulationsSupervisor do
  use DynamicSupervisor

  alias Fury.Simulation.SimulationSuperisor

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def start_child(simulation) do
    DynamicSupervisor.start_child(__MODULE__, simulation_spec(simulation))
  end

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  defp simulation_spec(simulation) do
    {SimulationSuperisor, simulation}
  end
end
