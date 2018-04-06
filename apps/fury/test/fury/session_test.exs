defmodule Fury.SessionTest do
  use ExUnit.Case

  alias Fury.Session
  alias Fury.Simulation
  alias Fury.Session.SessionServer

  setup do
    session = %Session{
      id: make_ref(),
      scenario: "think 10"
    }
    simulation = %Simulation{
      id: make_ref(),
      sessions: [session]
    }

    {:ok, simulation: simulation, session: session}
  end

  describe "start/2" do
    setup :start_session_supervisor
    setup :start_config_server

    test "starts new SessionServer",
        %{simulation: %{id: simulation_id}, session: %{id: session_id}} do
      {:ok, _} = Session.start(simulation_id, session_id)

      assert [_] = Registry.lookup(Fury.Registry.Session, session_id)
    end
  end

  describe "name/1" do
    test "returns :via tuple for name registration" do
      assert Session.name(:id) ==
        {:via, Registry, {Fury.Registry.Session, :id}}
    end
  end

  describe "supervisor_name/1" do
    test "returns :via tuple for name registration for supervisor" do
      assert Session.supervisor_name(:id) ==
        {:via, Registry, {Fury.Registry.SessionSupervisor, :id}}
    end
  end

  describe "get_requets/2" do
    setup :start_session_supervisor
    setup :start_config_server
    setup :start_server

    test "returns request", %{session: %{id: id}} do
      assert Session.get_request(id, 0) == {:think, 10}
    end
  end

  defp start_session_supervisor(%{simulation: %{id: id}}) do
    {:ok, _} = start_supervised({Fury.Session.SessionSupervisor, id})

    :ok
  end

  defp start_config_server(%{simulation: simulation}) do
    {:ok, _} = start_supervised({Fury.Simulation.ConfigServer, simulation})

    :ok
  end

  defp start_server(%{simulation: %{id: simulation_id}, session: %{id: id}}) do
    opts = [start: {SessionServer, :start_link, [simulation_id, id]}]
    {:ok, _} = start_supervised(SessionServer, opts)

    :ok
  end
end
