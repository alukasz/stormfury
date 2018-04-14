defmodule Fury.Simulation.SimulationSupervisor do
  use Supervisor, restart: :temporary

  alias Fury.Metrics
  alias Fury.Session.SessionsSupervisor
  alias Fury.Simulation.SimulationServer
  alias Fury.State.StateServer

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts)
  end

  def init([simulation_id, sessions]) do
    sessions = create_metrics(sessions)

    children = [
      {StateServer, simulation_id},
      {SimulationServer, [simulation_id, self()]},
      {SessionsSupervisor, sessions}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp create_metrics(sessions) do
    metrics_ref = Metrics.new()

    Enum.map(sessions, &Map.put(&1, :metrics_ref, metrics_ref))
  end
end
