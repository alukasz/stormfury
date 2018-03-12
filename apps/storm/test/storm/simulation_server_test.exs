defmodule Storm.SimulationServerTest do
  use ExUnit.Case, async: true

  alias Storm.Session
  alias Storm.Simulation
  alias Storm.SimulationServer

  setup do
    state = %Simulation{
      id: make_ref(),
      sessions: [%Session{id: make_ref()}]
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
    test "starts session", %{state: %{sessions: [%{id: session}]} = state} do
      SimulationServer.handle_info(:start_sessions, state)

      assert [{_, _}] = Registry.lookup(Storm.Session.Registry, session)
    end
  end
end
