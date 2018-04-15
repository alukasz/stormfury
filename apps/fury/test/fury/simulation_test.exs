defmodule Fury.SimulationTest do
  use ExUnit.Case

  import Mox

  alias Fury.Simulation
  alias Fury.Mock.Storm

  describe "start/1" do
    setup :set_mox_global
    setup do
      stub Storm, :send_metrics, fn _, _ -> :ok end

      :ok
    end

    test "starts new Simulation" do
      assert {:ok, pid} = Simulation.start(:id, [])
      assert is_pid(pid)
    end
  end
end
