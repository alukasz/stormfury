defmodule Fury.Metrics.MetricsReporterTest do
  use ExUnit.Case, async: true

  import Mox

  alias Fury.Metrics
  alias Fury.Metrics.MetricsReporter
  alias Fury.Mock.Storm

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
      state = %{simulation_id: :simulation_id, metrics_ref: ref}

      {:ok, state: state}
    end

    test "sends metrics data to Storm", %{state: state} do
      expect Storm, :send_metrics, fn _, _ -> :ok end

      MetricsReporter.handle_info(:report, state)

      verify!()
    end
  end
end
