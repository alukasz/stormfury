defmodule Storm.StateTest do
  use ExUnit.Case, async: true

  alias Storm.State
  alias Storm.State.StateServer

  setup do
    simulation_id = make_ref()
    session = %Db.Session{
      id: make_ref(),
      simulation_id: simulation_id,
    }
    simulation = %Db.Simulation{
      id: simulation_id,
      sessions: [session]
    }
    state = %Storm.State{
      simulation: simulation,
      sessions: Map.put(%{}, session.id, session),
      supervisor: self()
    }

    {:ok, simulation: simulation, session: session, state: state}
  end
  setup :insert_simulation

  describe "start_link/1" do
    test "starts server", %{simulation: %{id: id}} do
      assert {:ok, pid} = State.start_link([id, self()])
      assert is_pid(pid)
    end
  end

  describe "simulation/1" do
    setup :start_server

    test "returns state for simulation", %{simulation: %{id: id},
                                           server: server} do
      assert %Storm.Simulation{id: ^id} = State.simulation(server)
    end
  end

  describe "session/1" do
    setup :start_server

    test "returns state for session", %{session: %{id: id},
                                           server: server} do
      assert %Storm.Session{id: ^id} = State.session(server, id)
    end
  end

  defp insert_simulation(%{simulation: simulation}) do
    :ok = Db.Simulation.insert(simulation)

    :ok
  end
  defp start_server(%{simulation: %{id: id}}) do
    {:ok, pid} = start_supervised({StateServer, [id, self()]})

    {:ok, server: pid}
  end
end
