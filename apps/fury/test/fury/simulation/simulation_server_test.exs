defmodule Fury.Simulation.SimulationServerTest do
  use ExUnit.Case, async: true

  alias Fury.Simulation
  alias Fury.Simulation.ConfigServer
  alias Fury.Simulation.SimulationServer
  alias Fury.Simulation.SimulationServer.State

  setup do
    simulation = %Simulation{id: make_ref()}

    {:ok, simulation: simulation}
  end

  describe "start_link/1" do
    setup :start_config_server

    test "starts new SimulationServer", %{simulation: %{id: id}} do
      {:ok, _} = SimulationServer.start_link(id)

      assert [_] = Registry.lookup(Fury.Registry.Simulation, id)
    end
  end

  describe "init/1" do
    setup :start_config_server

    test "initializes state", %{simulation: %{id: id} = simulation} do
      state = %State{id: id, simulation: simulation}

      assert SimulationServer.init(id) == {:ok, state}
    end
  end

  defp start_config_server(%{simulation: simulation}) do
    {:ok, _} = start_supervised({ConfigServer, simulation})

    :ok
  end
end
