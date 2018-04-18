defmodule Storm.Metrics.MetricsCollectorTest do
  use Db.MnesiaCase

  alias Storm.Metrics.MetricsCollector
  alias Db.Metrics
  alias Db.NodeMetrics

  describe "init/1" do
    test "initializes state" do
      assert MetricsCollector.init(:simulation_id) == {:ok, :simulation_id}
    end
  end

  describe "handle_info :collect" do
    setup do
      for node <- [:node1, :node2, :node3] do
        %NodeMetrics{id: {:id, node}, clients: 1, clients_connected: 2,
                     messages_received: 3, messages_sent: 4}
        |> NodeMetrics.insert()
      end

      :ok
    end

    test "gathers all node metrics and inserts them to metrics table" do
      time = System.monotonic_time(:seconds)
      expected = %Metrics{id: {:id, time}, clients: 3, clients_connected: 6,
                          messages_received: 9, messages_sent: 12}

      assert {:noreply, :id} = MetricsCollector.handle_info(:collect, :id)

      assert expected in Metrics.get_by_simulation_id(:id)
    end
  end
end
