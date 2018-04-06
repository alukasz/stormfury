defmodule Fury.Session.SessionServerTest do
  use ExUnit.Case

  alias Fury.Session
  alias Fury.Simulation
  alias Fury.Session.SessionServer
  alias Fury.Session.SessionServer.State

  setup do
    session = %Session{
      id: make_ref()
    }
    simulation = %Simulation{
      id: make_ref(),
      sessions: [session]
    }

    {:ok, simulation: simulation, session: session}
  end

  describe "start_link/1" do
    setup :start_config_server

    test "starts new SessionServer",
        %{simulation: %{id: simulation_id}, session: %{id: session_id}} do
      {:ok, pid} = SessionServer.start_link(simulation_id, session_id)

      assert [{^pid, _}] = Registry.lookup(Fury.Registry.Session, session_id)
    end
  end

  describe "init/1" do
    setup :start_config_server

    test "initializes state",
        %{simulation: %{id: simulation_id}, session: %{id: session_id} } do
      state = %State{
        id: session_id,
        simulation_id: simulation_id,
        session: %Session{id: session_id}
      }

      assert SessionServer.init([simulation_id, session_id]) == {:ok, state}
    end
  end

  defp start_config_server(%{simulation: simulation}) do
    {:ok, _} = start_supervised({Fury.Simulation.ConfigServer, simulation})

    :ok
  end
end
