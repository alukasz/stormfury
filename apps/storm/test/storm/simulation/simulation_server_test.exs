defmodule Storm.SimulationServerTest do
  use ExUnit.Case, async: true

  import Mox

  alias Storm.Simulation.SimulationServer
  alias Storm.Mock

  setup do
    id = make_ref()
    simulation = %Db.Simulation{
      id: id,
      duration: 0,
      sessions: [%Db.Session{id: make_ref(), simulation_id: id}]
    }

    {:ok, simulation: simulation}
  end

  describe "init/1" do
    setup %{simulation: simulation} do
      Db.Simulation.insert(simulation)
    end

    test "initializes state", %{simulation: %{id: id} = simulation} do
      assert SimulationServer.init(id) == {:ok, simulation}
    end

    test "restores state from Db", %{simulation: %{id: id} = simulation} do
      Db.Simulation.update(simulation, clients_started: 20)

      assert {:ok, %{clients_started: 20}} = SimulationServer.init(id)
    end

    test "sends message to start dependencies", %{simulation: %{id: id}} do
      SimulationServer.init(id)

      assert_receive :initialize
    end
  end

  describe "handle_call({:get_ids, number}, _, _)" do
    setup %{simulation: simulation} do
      Db.Repo.insert(simulation)

      :ok
    end

    test "replies with range of clients ids to start", %{simulation: simulation} do
      assert {:reply, 1..10, _} =
        SimulationServer.handle_call({:get_ids, 10}, :from, simulation)
    end

    test "increases number of clients started", %{simulation: simulation} do
      assert {_, _, %{clients_started: 10}} =
        SimulationServer.handle_call({:get_ids, 10}, :from, simulation)
    end

    test "updates Db.Simulation", %{simulation: simulation} do
      SimulationServer.handle_call({:get_ids, 10}, :from, simulation)

      assert %{clients_started: 10} = Db.Repo.get(Db.Simulation, simulation.id)
    end
  end

  describe "handle_info(:initialize, _)" do
    setup do
      stub Mock.Fury, :start_simulation, fn _ -> {[{:node, :ok}], []} end

      :ok
    end

    test "sends message to perform simulation", %{simulation: simulation} do
      SimulationServer.handle_info(:initialize, simulation)

      assert_receive :perform
    end

    test "creates pg2 group for remote simulations", %{simulation: simulation} do
      SimulationServer.handle_info(:initialize, simulation)

      assert Fury.group(simulation.id) in :pg2.which_groups()
    end

    test "starts remote simulations", %{simulation: simulation} do
      expect Mock.Fury, :start_simulation, fn _ -> {[{:node, :ok}], []} end

      SimulationServer.handle_info(:initialize, simulation)

      verify!()
    end
  end

  describe "handle_info(:perform, _)" do
    setup %{simulation: %{sessions: [%{id: id}]}} do
      Registry.register(Storm.Registry.Launcher, id, nil)

      :ok
    end

    test "sends message to cleanup simulation", %{simulation: simulation} do
      spawn fn ->
        SimulationServer.handle_info(:perform, simulation)

        assert_receive :cleanup
      end
    end

    test "turns on LauncherServer", %{simulation: simulation} do
      spawn fn ->
        SimulationServer.handle_info(:perform, simulation)
      end

      assert_receive {:"$gen_call", _, :perform}
    end
  end
end
