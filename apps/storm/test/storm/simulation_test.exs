defmodule Storm.SimulationTest do
  use ExUnit.Case, async: true

  alias Storm.Simulation

  setup do
    state = %Simulation{
      id: make_ref(),
    }

    {:ok, state: state}
  end

  describe "new/1" do
    test "starts new Simulation", %{state: %{id: id} = state} do
      assert {:ok, pid} = Simulation.new(state)
      assert [{^pid, _}] = Registry.lookup(Storm.Simulation.Registry, id)
    end
  end
end
