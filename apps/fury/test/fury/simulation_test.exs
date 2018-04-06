defmodule Fury.SimulationTest do
  use ExUnit.Case, async: true

  alias Fury.Simulation

  setup do
    simulation = %Simulation{id: make_ref()}

    {:ok, simulation: simulation}
  end

  describe "start/1" do
    setup do
      {:ok, _} = start_supervised(Fury.SimulationsSupervisor)

      :ok
    end

    test "starts new SimulationServer", %{simulation: simulation} do
      {:ok, _} = Simulation.start(simulation)

      assert [_] = Registry.lookup(Fury.Registry.Simulation, simulation.id)
    end
  end

  describe "name/1" do
    test "returns via tuple for SimulationServer for struct",
        %{simulation: simulation} do
      assert Simulation.name(simulation) ==
        {:via, Registry, {Fury.Registry.Simulation, simulation.id}}
    end

    test "returns via tuple for SimulationServer for term",
        %{simulation: %{id: id}} do
      assert Simulation.name(id) ==
      {:via, Registry, {Fury.Registry.Simulation, id}}
    end
  end
end
