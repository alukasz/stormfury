defmodule Fury.Metrics.MetricsReporterTest do
  use ExUnit.Case, async: true

  alias Fury.Metrics
  alias Fury.Metrics.MetricsReporter

  describe "init/1" do
    test "initializes state" do
      assert MetricsReporter.init([:simulation_id, :metrics_ref]) ==
        {:ok, %{simulation_id: :simulation_id, metrics_ref: :metrics_ref}}
    end

    test "sends message to send metrics" do
      MetricsReporter.init([:simulation_id, :metrics_ref])

      assert_receive :report
    end
  end

  describe "handle_info :report" do
    setup do
      ref = Metrics.new()
      populate_metrics(ref)
      state = %{simulation_id: :simulation_id, metrics_ref: ref}

      {:ok, state: state}
    end

    test "inserts metrics data to NodeMetrics table", %{state: state} do
      id = {state.simulation_id, node()}
      expected = %Db.NodeMetrics{id: id, clients: 1, clients_connected: 2,
                                 messages_received: 3, messages_sent: 4}

      MetricsReporter.handle_info(:report, state)

      assert Db.Repo.get(Db.NodeMetrics, id) == expected
    end

    defp populate_metrics(ref) do
      metrics = [clients: 1, clients_connected: 2, messages_received: 3,
                 messages_sent: 4]

      for {metric, times} <- metrics do
        for _ <- 1..times do
          Metrics.incr(ref, 1, metric)
        end
      end
    end
  end
end
