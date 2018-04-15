defmodule Fury.Metrics.MetricsReporter do
  use GenServer

  alias Fury.Metrics

  @interval :timer.seconds(1)
  @storm_bridge Application.get_env(:fury, :storm_bridge)

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init([simulation_id, metrics_ref]) do
    send(self(), :report)

    {:ok, %{simulation_id: simulation_id, metrics_ref: metrics_ref}}
  end

  def handle_info(:report, %{simulation_id: id, metrics_ref: ref} = state) do
    schedule_report()
    metrics = Metrics.get(ref)
    @storm_bridge.send_metrics(id, metrics)

    {:noreply, state}
  end

  defp schedule_report do
    Process.send_after(self(), :report, @interval)
  end
end
