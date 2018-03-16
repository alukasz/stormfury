defmodule Storm.SimulationServerTest do
  use ExUnit.Case, async: true

  alias Storm.Session
  alias Storm.SessionSupervisor
  alias Storm.Simulation
  alias Storm.SimulationServer
  alias Storm.SimulationServer.State

  setup do
    id = make_ref()
    simulation = %Simulation{
      id: id,
      sessions: [%Session{id: make_ref(), simulation_id: id}],
      nodes: [:nonode]
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

    test "sends message to start sessions", %{simulation: simulation} do
      SimulationServer.init(simulation)

      assert_receive :start_sessions
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
    setup %{simulation: simulation} do
      {:ok, _} = start_supervised({SessionSupervisor, simulation})

      :ok
    end

    test "starts session", %{state: state} do
      %{simulation: %{sessions: [%{id: session_id}]}} = state

      SimulationServer.handle_info(:start_sessions, state)

      assert [{_, _}] = Registry.lookup(Storm.Session.Registry, session_id)
    end
  end
end
