defmodule Storm.SimulationServerTest do
  use ExUnit.Case, async: true

  import Mox

  alias Storm.SessionSupervisor
  alias Storm.SimulationServer
  alias Storm.SimulationServer.State
  alias Storm.Mock.Fury

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

  describe "handle_info(:start_sessions, state)" do
    setup %{state: state, simulation: simulation} do
      {:ok, _} = start_supervised({SessionSupervisor, simulation})
      simulation = %{simulation | hosts: [:n1, :n2, :n3]}
      state = %{state | simulation: simulation, nodes: [:n1, :n2, :n3]}

      {:ok, state: state, simulation: simulation}
    end

    test "starts local sessions", %{state: state, simulation: simulation} do
      stub Fury, :start_sessions, fn _, _ -> {:ok, :pid} end
      %{sessions: [%{id: session_id}]} = simulation

      SimulationServer.handle_info(:start_sessions, state)

      assert [{_, _}] = Registry.lookup(Storm.Session.Registry, session_id)
    end

    test "starts remote sessions", %{state: state} do
      expect Fury, :start_sessions, 3, fn _, _ -> {:ok, :pid} end

      SimulationServer.handle_info(:start_sessions, state)

      verify!()
    end
  end
end
