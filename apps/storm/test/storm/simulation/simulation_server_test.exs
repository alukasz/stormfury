defmodule Storm.SimulationServerTest do
  use ExUnit.Case, async: true

  import Mox
  import Storm.SimulationHelper

  alias Storm.Simulation
  alias Storm.Simulation.SimulationServer
  alias Storm.Mock

  setup :default_simulation

  describe "start_link/1" do
    setup :insert_simulation

    test "starts new SimulationServer", %{simulation: %{id: id}} do
      assert {:ok, pid} = SimulationServer.start_link([id, self()])
      assert is_pid(pid)
    end

    test "registers name", %{simulation: %{id: id}} do
      SimulationServer.start_link([id, :pid])

      assert [_] = Registry.lookup(Storm.Registry.Simulation, id)
    end
  end

  describe "init/1" do
    setup :insert_simulation

    test "initializes state", %{simulation: %{id: id}} do
      assert {:ok, %Simulation{id: ^id, supervisor_pid: :pid}} =
        SimulationServer.init([id, :pid])
    end

    test "restores state from Db", %{simulation: simulation} do
      insert_simulation(simulation, clients_started: 20)

      assert {:ok, %{clients_started: 20}} =
        SimulationServer.init([simulation.id, :pid])
    end
  end

  describe "handle_call {:get_ids, number}" do
    setup :insert_simulation

    test "replies with range of ids to start", %{simulation: simulation} do
      assert {:reply, 1..10, _} =
        SimulationServer.handle_call({:get_ids, 10}, :from, simulation)
    end

    test "increases number of clients started", %{simulation: simulation} do
      assert {_, _, %{clients_started: 10}} =
        SimulationServer.handle_call({:get_ids, 10}, :from, simulation)
    end

    test "updates Db.Simulation", %{simulation: simulation} do
      SimulationServer.handle_call({:get_ids, 10}, :from, simulation)

      assert %{clients_started: 10} = Db.Simulation.get(simulation.id)
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
    setup %{simulation: simulation} do
      {:ok, simulation: %{simulation | duration: 0, sessions_pids: [self()]}}
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

      assert_receive {:"$gen_cast", :perform}
    end
  end
end
