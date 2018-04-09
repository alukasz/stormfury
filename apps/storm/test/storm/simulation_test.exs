defmodule Storm.SimulationTest do
  use ExUnit.Case

  import Mox

  alias Storm.Simulation
  alias Storm.Simulation.SimulationServer
  alias Storm.SimulationsSupervisor
  alias Storm.Mock.Fury

  setup do
    simulation = %Db.Simulation{id: make_ref(), duration: 1}

    {:ok, simulation: simulation}
  end

  describe "start/1" do
    setup :set_mox_global

    test "starts new Simulation", %{simulation: simulation} do
      stub Fury, :start_simulation, fn _ -> {[], []} end

      assert {:ok, _} = Simulation.start(simulation)
      assert [_] = Registry.lookup(Storm.Registry.Simulation, simulation.id)
    end
  end

  describe "terminate/1" do
    setup :set_mox_global
    setup %{simulation: simulation} do
      stub Fury, :start_simulation, fn _ -> {[], []} end
      {:ok, _} = SimulationsSupervisor.start_child(simulation)

      :ok
    end

    test "terminates Simulation", %{simulation: simulation} do
      assert :ok = Simulation.terminate(simulation)
      assert [] = Registry.lookup(Storm.Registry.Simulation, simulation.id)
    end
  end

  describe "name/1" do
    test "returns :via tuple for name registration" do
      assert Simulation.name(:id) ==
        {:via, Registry, {Storm.Registry.Simulation, :id}}
    end
  end

  describe "get_ids/1" do
    setup :set_mox_global
    setup :start_server

    test "returns range of clients ids", %{simulation: %{id: simulation_id}} do
      assert 1..10 = Simulation.get_ids(simulation_id, 10)
      assert 11..20 = Simulation.get_ids(simulation_id, 10)
    end
  end

  defp start_server(%{simulation: simulation}) do
    stub Fury, :start_simulation, fn _ -> {[], []} end
    :ok = Db.Repo.insert(simulation)
    {:ok, _} = start_supervised({SimulationServer, simulation})

    :ok
  end
end
