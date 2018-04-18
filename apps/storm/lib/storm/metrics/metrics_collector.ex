defmodule Storm.Metrics.MetricsCollector do
  use GenServer

  alias Db.NodeMetrics
  alias Db.Metrics

  @interval :timer.seconds(1)

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(simulation_id) do
    schedule()

    {:ok, simulation_id}
  end

  def handle_info(:collect, simulation_id) do
    schedule()
    collect_metrics(simulation_id)

    {:noreply, simulation_id}
  end

  defp collect_metrics(simulation_id) do
    simulation_id
    |> NodeMetrics.get_by_simulation_id()
    |> Enum.map(&Map.take(&1, [:clients, :clients_connected,
                              :messages_sent, :messages_received]))
    |> sum_node_metrics()
    |> insert_metrics(simulation_id)
  end

  defp sum_node_metrics([node_metric | rest]) do
    Enum.reduce(rest, node_metric, fn current, sum ->
      Map.merge(sum, current, fn _, v1, v2 -> v1 + v2 end)
    end)
  end

  defp insert_metrics(metrics, simulation_id) do
    time = System.monotonic_time(:seconds)
    attrs = Map.put(metrics, :id, {simulation_id, time})
    metrics = struct(Metrics, attrs)
    :ok = Metrics.insert(metrics)
  end

  defp schedule do
    Process.send_after(self(), :collect, @interval)
  end
end
