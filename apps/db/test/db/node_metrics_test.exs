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

      assert :ok = NodeMetrics.insert(%NodeMetrics{id: {:id, :node}, clients: 100})

      assert %NodeMetrics{id: {:id, :node}, clients: 100} =
        Repo.get(NodeMetrics, {:id, :node})
    end
  end
end
