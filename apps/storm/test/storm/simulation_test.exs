defmodule Storm.SimulationTest do
  use ExUnit.Case, async: true

  alias Storm.Simulation
  alias Storm.Simulation.SimulationServer

  setup do
    simulation = %Db.Simulation{id: make_ref()}

    {:ok, simulation: simulation}
  end

  describe "new/1" do
    test "starts new Simulation", %{simulation: simulation} do
      assert {:ok, _} = Simulation.new(simulation)
      assert [{_, _}] =
        Registry.lookup(Storm.Simulation.Registry, simulation.id)
    end
  end

  describe "get_ids/1" do
    setup :start_server

    test "returns range of clients ids", %{simulation: %{id: simulation_id}} do
      assert 1..10 = Simulation.get_ids(simulation_id, 10)
    end
  end

  defp start_server(%{simulation: simulation}) do
    {:ok, _} = start_supervised({SimulationServer, simulation})

    :ok
  end
end
