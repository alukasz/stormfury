defmodule Fury.Simulation.ConfigTest do
  use ExUnit.Case, async: true

  alias Fury.Client
  alias Fury.Session
  alias Fury.Simulation
  alias Fury.Simulation.Config
  alias Fury.Simulation.ConfigServer
  alias Fury.Mock.{Protocol, Transport}

  setup do
    simulation = %Simulation{
      id: make_ref(),
      url: "localhost",
      transport_mod: Transport,
      protocol_mod: Protocol,
      sessions: [%Session{id: make_ref()}]
    }
    {:ok, _} = start_supervised({ConfigServer, simulation})

    {:ok, simulation: simulation}
  end

  describe "simulation/1" do
    test "returns Simulation", %{simulation: simulation} do
      assert Config.simulation(simulation.id) == simulation
    end

    test "when simulation does not exist" do
      assert {:noproc, _} = catch_exit(Config.simulation(:noproc))
    end
  end

  describe "session/2" do
    test "returns Session", %{simulation: simulation} do
      %{sessions: [%{id: session_id} = session]} = simulation

      assert Config.session(simulation.id, session_id) == session
    end

    test "when session does not exist", %{simulation: simulation} do
      assert Config.session(simulation.id, nil) == :error
    end
  end

  describe "client/1" do
    test "returns Client config", %{simulation: simulation} do
      assert Config.client(simulation.id) == %Client{
        url: "localhost",
        transport_mod: Transport,
        protocol_mod: Protocol,
      }
    end
  end
end
