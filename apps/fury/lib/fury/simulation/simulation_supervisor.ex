defmodule Fury.Simulation.SimulationSupervisor do
  use Supervisor, restart: :temporary

  alias Fury.Metrics
  alias Fury.Metrics.MetricsReporter
  alias Fury.Session.SessionsSupervisor
  alias Fury.Simulation.SimulationServer
  alias Fury.State.StateServer

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts)
  end

  def init([simulation_id, sessions]) do
    {metrics_ref, sessions} = create_metrics(sessions)

    children = [
      {StateServer, simulation_id},
      {MetricsReporter, [simulation_id, metrics_ref]},
      {SimulationServer, [simulation_id, self()]},
      {SessionsSupervisor, sessions}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp create_metrics(sessions) do
    metrics_ref = Metrics.new()
    sessions = Enum.map(sessions, &Map.put(&1, :metrics_ref, metrics_ref))

    {metrics_ref, sessions}
  end
end
