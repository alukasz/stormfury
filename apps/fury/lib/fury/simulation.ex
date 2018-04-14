defmodule Fury.Simulation do
  alias Fury.Metrics
  alias Fury.Simulation.SimulationsSupervisor

  def start(simulation_id, sessions) do
    sessions = create_metrics(sessions)

    SimulationsSupervisor.start_child(simulation_id, sessions)
  end

  def terminate(simulation_sup_pid) do
    SimulationsSupervisor.terminate_child(simulation_sup_pid)
  end

  defp create_metrics(sessions) do
    metrics_ref = Metrics.new()

    Enum.map(sessions, &Map.put(&1, :metrics_ref, metrics_ref))
  end
end
