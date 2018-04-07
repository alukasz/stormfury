defmodule Storm.SimulationServerTest do
  use ExUnit.Case, async: true

  alias Storm.SimulationServer
  alias Storm.SimulationServer.State

  setup do
    id = make_ref()
    simulation = %Db.Simulation{
      id: id,
      sessions: [%Db.Session{id: make_ref(), simulation_id: id}]
    }
    state = %State{simulation: simulation}

    {:ok, state: state, simulation: simulation}
  end

  describe "name/1" do
    test "returns :via tuple for name registration" do
      assert SimulationServer.name(:id) ==
        {:via, Registry, {Storm.Simulation.Registry, :id}}
    end
  end

  describe "init/1" do
    test "initializes state", %{simulation: simulation, state: state} do
      assert SimulationServer.init(simulation) == {:ok, state}
    end

    test "sends message to start slave nodes", %{simulation: simulation} do
      SimulationServer.init(simulation)

      assert_receive :start_slaves
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
end
