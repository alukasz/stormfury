defmodule Fury.Metrics.MetricsReporter do
  use GenServer

  alias Fury.Metrics
  alias Db.NodeMetrics

  @interval :timer.seconds(1)

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init([simulation_id, metrics_ref]) do
    send(self(), :report)

    {:ok, %{simulation_id: simulation_id, metrics_ref: metrics_ref}}
  end

  def handle_info(:report, %{simulation_id: id, metrics_ref: ref} = state) do
    schedule_report()
    update_node_metrics(id, ref)

    {:noreply, state}
  end

  defp update_node_metrics(simulation_id, metrics_ref) do
    metrics = Metrics.get(metrics_ref)
    node_metrics = struct(NodeMetrics, [{:id, {simulation_id, node()}} | metrics])
    NodeMetrics.insert(node_metrics)
  end

  defp schedule_report do
    Process.send_after(self(), :report, @interval)
  end
end
