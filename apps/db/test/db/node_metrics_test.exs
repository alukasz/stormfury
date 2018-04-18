defmodule Db.NodeMetricsTest do
  use Db.MnesiaCase

  alias Db.NodeMetrics
  alias Db.Repo

  describe "insert/1" do
    test "inserts node metrics" do
      assert :ok = NodeMetrics.insert(%NodeMetrics{id: {:id, :node}})

      assert %NodeMetrics{id: {:id, :node}} =
        Repo.get(NodeMetrics, {:id, :node})
    end

    test "overwrites existing node metrics" do
      Repo.insert(%NodeMetrics{id: {:id, :node}})

      assert :ok =
        NodeMetrics.insert(%NodeMetrics{id: {:id, :node}, clients: 100})

      assert %NodeMetrics{id: {:id, :node}, clients: 100} =
        Repo.get(NodeMetrics, {:id, :node})
    end
  end

  describe "get_by_simulation_id/1" do
    setup do
      Repo.insert(%NodeMetrics{id: {:id, :node1}})
      Repo.insert(%NodeMetrics{id: {:id, :node2}})
      Repo.insert(%NodeMetrics{id: {:other_id, :node1}})

      :ok
    end

    test "returns node metrics for simulation" do
      metrics = NodeMetrics.get_by_simulation_id(:id)

      assert %NodeMetrics{id: {:id, :node1}} in metrics
      assert %NodeMetrics{id: {:id, :node2}} in metrics
    end

    test "does not returns metrics for other simulations" do
      metrics = NodeMetrics.get_by_simulation_id(:id)

      refute %NodeMetrics{id: {:other_id, :node1}} in metrics
    end
  end
end
