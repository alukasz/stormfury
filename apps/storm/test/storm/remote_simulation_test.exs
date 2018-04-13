defmodule Storm.RemoteSimulationTest do
  use ExUnit.Case, async: true

  import Storm.SimulationHelper
  import ExUnit.CaptureLog
  import Mox

  alias Storm.RemoteSimulation
  alias Storm.Mock

  setup :default_simulation

  describe "start/1" do
    test "invokes FuryBridge", %{simulation: simulation} do
      expect Mock.Fury, :start_simulation, fn _, _ -> {[], []} end

      RemoteSimulation.start(simulation)
    end

    test "creates pg2 group", %{simulation: simulation} do
      stub Mock.Fury, :start_simulation, fn _, _ -> {[], []} end

      RemoteSimulation.start(simulation)

      assert Fury.group(simulation.id) in :pg2.which_groups()
    end

    test "logs error when failed to start remote simulation",
        %{simulation: simulation} do
      reason = :not_remote_enough
      node = :bad@node
      error = {node, {:error, reason}}
      stub Mock.Fury, :start_simulation, fn _, _ -> {[error], []} end

      logs = capture_log(fn -> RemoteSimulation.start(simulation) end)

      assert logs =~ "Failed to start simulation on node :#{node}"
      assert logs =~ "#{reason}"
    end

    test "logs error when failed to connect to node",
      %{simulation: simulation} do
      node = :bad@node
      stub Mock.Fury, :start_simulation, fn _, _ -> {[], [node]} end

      logs = capture_log(fn -> RemoteSimulation.start(simulation) end)

      assert logs =~ "Failed to start simulations on nodes [:#{node}]"
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
