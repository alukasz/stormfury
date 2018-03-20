defmodule Storm.Simulation.LoadBalancerTest do
  use ExUnit.Case, async: true

  alias Storm.Simulation.LoadBalancer
  alias Storm.Simulation.LoadBalancerServer

  setup do
    simulation = %Db.Simulation{id: make_ref()}
    {:ok, _} = start_supervised({LoadBalancerServer, simulation})

    {:ok, id: simulation.id}
  end

  describe "start_clients/3" do
    test "returns :ok", %{id: id} do
      assert LoadBalancer.start_clients(id, :session, 1..10) == :ok
    end
  end
end
