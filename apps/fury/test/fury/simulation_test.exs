defmodule Fury.SimulationTest do
  use ExUnit.Case

  alias Fury.Simulation

  describe "start/1" do
    test "starts new Simulation" do
      assert {:ok, pid} = Simulation.start(:id, [])
      assert is_pid(pid)
    end
  end
end
