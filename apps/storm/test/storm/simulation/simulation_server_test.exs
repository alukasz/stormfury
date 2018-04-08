defmodule Storm.SimulationServerTest do
  use ExUnit.Case, async: true

  import Mox

  alias Storm.Simulation.SimulationServer
  alias Storm.Simulation.SimulationServer.State
  alias Storm.Mock

  setup do
    id = make_ref()
    simulation = %Db.Simulation{
      id: id,
      duration: 0,
      sessions: [%Db.Session{id: make_ref(), simulation_id: id}]
    }
    state = %State{simulation: simulation}

    {:ok, state: state, simulation: simulation}
  end

  describe "init/1" do
    test "initializes state", %{simulation: simulation, state: state} do
      assert SimulationServer.init(simulation) == {:ok, state}
    end

    test "sends message to start dependencies", %{simulation: simulation} do
      SimulationServer.init(simulation)

      assert_receive :initialize
    end
  end

  describe "handle_call({:get_ids, number}, _, _)" do
    test "replies with range of clients ids to start", %{state: state} do
      assert {:reply, 1..10, _} =
        SimulationServer.handle_call({:get_ids, 10}, :from, state)
    end

    test "increases number of clients started", %{state: state} do
      assert {_, _, %{clients_started: 10}} =
        SimulationServer.handle_call({:get_ids, 10}, :from, state)
    end
  end

  describe "handle_info(:initialize, _)" do
    setup do
      stub Mock.Fury, :start_simulation, fn _ -> {[{:node, :ok}], []} end

      :ok
    end

    test "sends message to perform simulation", %{state: state} do
      SimulationServer.handle_info(:initialize, state)

      assert_receive :perform
    end

    test "creates pg2 group for remote simulations", %{state: state} do
      SimulationServer.handle_info(:initialize, state)

      assert Fury.group(state.simulation.id) in :pg2.which_groups()
    end

    test "starts remote simulations", %{state: state} do
      expect Mock.Fury, :start_simulation, fn _ -> {[{:node, :ok}], []} end

      SimulationServer.handle_info(:initialize, state)

      verify!()
    end
  end

  describe "handle_info(:perform, _)" do
    setup %{simulation: %{sessions: [%{id: id}]}} do
      Registry.register(Storm.Registry.Launcher, id, nil)

      :ok
    end

    test "sends message to cleanup simulation", %{state: state} do
      spawn fn ->
        SimulationServer.handle_info(:perform, state)

        assert_receive :cleanup
      end
    end

    test "turns on LauncherServer", %{state: state} do
      spawn fn ->
        SimulationServer.handle_info(:perform, state)
      end

      assert_receive {:"$gen_call", _, :perform}
    end
  end
end
