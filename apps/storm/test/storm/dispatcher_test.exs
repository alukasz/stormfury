defmodule Storm.DispatcherTest do
  use ExUnit.Case, async: true

  import Storm.SimulationHelper

  alias Storm.Dispatcher
  alias Storm.Dispatcher.DispatcherServer

  setup :default_simulation
  setup :insert_simulation
  setup :start_simulation_server

  describe "start_clients/3" do
    setup %{simulation: %{id: simulation_id}} do
      {:ok, pid} = start_supervised({DispatcherServer, simulation_id})

      {:ok, server_pid: pid}
    end

    test "returns :ok", %{server_pid: pid} do
      assert Dispatcher.start_clients(pid, :session, 1..10) == :ok
    end
  end
end
