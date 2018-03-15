defmodule Storm.SimulationTest do
  use ExUnit.Case, async: true

  alias Storm.Simulation
  alias Storm.SimulationServer

  setup do
    state = %Simulation{
      id: make_ref(),
      nodes: [:nonode]
    }

    {:ok, state: state, id: state.id}
  end

  describe "new/1" do
    test "starts new Simulation", %{state: %{id: id} = state} do
      assert {:ok, _} = Simulation.new(state)
      assert [{_, _}] = Registry.lookup(Storm.Simulation.Registry, id)
    end
  end

  describe "get_node/1" do
    setup :start_server

    test "returns one of nodes for simulation", %{id: id} do
      assert {:ok, :nonode} = Simulation.get_node(id)
    end
  end

  describe "get_ids/1" do
    setup :start_server

    test "returns range of clients ids", %{id: id} do
      assert 1..10 = Simulation.get_ids(id, 10)
    end
  end

  defp start_server(%{state: state}) do
    {:ok, _} = start_supervised({SimulationServer, state})

    :ok
  end
end
