defmodule Fury.ServerTest do
  use ExUnit.Case, async: true

  alias Fury.Server
  alias Fury.Simulation

  setup do
    simulation = %Simulation{id: make_ref()}

    {:ok, simulation: simulation}
  end

  describe "handle_call {:start_simulation, simulation}" do
    test "starts simulation", %{simulation: simulation} do
      {:reply, {:ok, _}, _} =
        Server.handle_call({:start_simulation, simulation}, :from, %{})

      assert [_] = Registry.lookup(Fury.Registry.Simulation, simulation.id)
    end

    test "creates pg2 group", %{simulation: simulation} do
      Server.handle_call({:start_simulation, simulation}, :from, %{})

      assert Fury.group(simulation.id) in :pg2.which_groups()
    end
  end
end
