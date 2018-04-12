defmodule Storm.LauncherTest do
  use ExUnit.Case, async: true

  import Storm.SimulationHelper

  alias Storm.Launcher
  alias Storm.Launcher.LauncherServer

  setup :default_simulation
  setup :default_session
  setup :insert_simulation
  setup :start_simulation_server
  setup :start_server

  describe "perform/1" do
    test "returns :ok", %{server_pid: server} do
      assert Launcher.perform(server) == :ok
    end
  end

  def start_server(%{simulation: %{id: id}, session: %{id: session_id}}) do
    {:ok, pid} = start_supervised({LauncherServer, [id, session_id]})

    {:ok, server_pid: pid}
  end
end
