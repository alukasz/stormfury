defmodule Fury.Simulation.SimulationServerTest do
  use ExUnit.Case, async: true

  alias Fury.Simulation
  alias Fury.Simulation.SimulationServer
  alias Fury.Simulation.SimulationServer.State

  setup do
    simulation = %Simulation{id: make_ref()}

    {:ok, simulation: simulation}
  end

  describe "start_link/1" do
    test "starts new SimulationServer", %{simulation: simulation} do
      {:ok, _} = SimulationServer.start_link(simulation)

      assert [_] = Registry.lookup(Fury.Registry.Simulation, simulation.id)
    end
  end

  describe "init/1" do
    test "initializes state", %{simulation: simulation} do
      state = %State{id: simulation.id, simulation: simulation}
      assert SimulationServer.init(simulation) == {:ok, state}
    end
  end
end
