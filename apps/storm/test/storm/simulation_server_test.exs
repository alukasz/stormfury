defmodule Storm.SimulationServerTest do
  use ExUnit.Case, async: true

  alias Storm.Session
  alias Storm.SessionSupervisor
  alias Storm.Simulation
  alias Storm.SimulationServer

  setup do
    id = make_ref()
    state = %Simulation{
      id: id,
      sessions: [%Session{id: make_ref(), simulation_id: id}]
    }

    {:ok, state: state}
  end

  describe "init/1" do
    test "initializes state", %{state: state} do
      assert SimulationServer.init(state) == {:ok, state}
    end

    test "sends message to start sessions", %{state: state} do
      SimulationServer.init(state)

      assert_receive :start_sessions
    end
  end

  describe "handle_info(:start_sessions, state)" do
    setup %{state: %{id: simulation_id}} do
      {:ok, _} = start_supervised({SessionSupervisor, simulation_id})

      :ok
    end

    test "starts session", %{state: %{sessions: [%{id: session_id}]} = state} do
      SimulationServer.handle_info(:start_sessions, state)

      assert [{_, _}] = Registry.lookup(Storm.Session.Registry, session_id)
    end
  end
end
