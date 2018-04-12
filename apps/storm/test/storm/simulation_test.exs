defmodule Storm.SimulationTest do
  use ExUnit.Case, async: true

  import Storm.SimulationHelper

  alias Storm.Simulation
  alias Storm.SimulationsSupervisor

  setup :default_simulation
  setup :insert_simulation

  describe "start/1" do
    test "starts new Simulation", %{simulation: %{id: id}} do
      assert {:ok, _} = Simulation.start(id)
      assert [_] = Registry.lookup(Storm.Registry.Simulation, id)
    end
  end

  describe "terminate/1" do
    setup %{simulation: %{id: id}} do
      {:ok, pid} = SimulationsSupervisor.start_child(id)

      {:ok, simulation_sup: pid}
    end

    test "terminates Simulation", %{simulation: %{id: id},
                                    simulation_sup: pid} do
      assert :ok = Simulation.terminate(pid)

      :timer.sleep(50)
      assert [] = Registry.lookup(Storm.Registry.Simulation, id)
    end
  end

  describe "name/1" do
    test "returns :via tuple for name registration" do
      assert Simulation.name(:id) ==
        {:via, Registry, {Storm.Registry.Simulation, :id}}
    end
  end

  describe "get_ids/1" do
    setup :start_simulation_server

    test "returns range of clients ids", %{simulation: %{id: simulation_id}} do
      assert 1..10 = Simulation.get_ids(simulation_id, 10)
      assert 11..20 = Simulation.get_ids(simulation_id, 10)
      assert 21..25 = Simulation.get_ids(simulation_id, 5)
    end
  end
end
