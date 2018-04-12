defmodule Storm.RemoteSimulationTest do
  use ExUnit.Case, async: true

  import Storm.SimulationHelper
  import Mox

  alias Storm.RemoteSimulation
  alias Storm.Mock

  setup :default_simulation

  describe "start/1" do
    test "invokes FuryBridge", %{simulation: simulation} do
      expect Mock.Fury, :start_simulation, fn _ -> {[], []} end

      RemoteSimulation.start(simulation)
    end

    test "creates pg2 group", %{simulation: simulation} do
      stub Mock.Fury, :start_simulation, fn _ -> {[], []} end

      RemoteSimulation.start(simulation)

      assert Fury.group(simulation.id) in :pg2.which_groups()
    end
  end

  describe "terminate/1" do
    setup %{simulation: %{id: id}} do
      group = Fury.group(id)
      :pg2.create(group)
      :pg2.join(group, self())

      :ok
    end

    test "invokes FuryBridge", %{simulation: simulation} do
      spawn_link fn ->
        RemoteSimulation.terminate(simulation)
      end

      assert_receive {_, _, :terminate}
    end
  end
end
