defmodule Db.MetricsTest do
  use Db.MnesiaCase

  alias Db.Metrics
  alias Db.Repo

  describe "insert/1" do
    test "inserts node metrics" do
      assert :ok = Metrics.insert(%Metrics{id: {:id, :node}})

      assert %Metrics{id: {:id, :node}} = Repo.get(Metrics, {:id, :node})
    end

    test "overwrites existing node metrics" do
      Repo.insert(%Metrics{id: {:id, :node}})

      assert :ok = Metrics.insert(%Metrics{id: {:id, :node}, clients: 100})

      assert %Metrics{id: {:id, :node}, clients: 100} =
        Repo.get(Metrics, {:id, :node})
    end
  end

  describe "get_by_simulation_id/1" do
    setup do
      Repo.insert(%Metrics{id: {:id, 1}})
      Repo.insert(%Metrics{id: {:id, 2}})
      Repo.insert(%Metrics{id: {:other_id, 1}})

      :ok
    end

    test "returns node metrics for simulation" do
      metrics = Metrics.get_by_simulation_id(:id)

      assert %Metrics{id: {:id, 1}} in metrics
      assert %Metrics{id: {:id, 2}} in metrics
    end

    test "does not returns metrics for other simulations" do
      metrics = Metrics.get_by_simulation_id(:id)

      refute %Metrics{id: {:other_id, 1}} in metrics
    end
  end
end
