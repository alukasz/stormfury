defmodule Storm.StateTest do
  use ExUnit.Case, async: true

  import Storm.SimulationHelper

  alias Storm.State
  alias Storm.State.StateServer

  setup :default_simulation
  setup :default_session
  setup :insert_simulation
  setup %{simulation: simulation, session: session} do
    state = %Storm.State{
      simulation: simulation,
      sessions: Map.put(%{}, session.id, session),
      supervisor_pid: self()
    }

    {:ok, state: state}
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

  describe "update_simulation/2" do
    setup :start_server

    test "updates simulation in Db", %{simulation: %{id: id}, server: server} do
      assert :ok = State.update_simulation(server, clients_started: 100)

      wait_for_cast()
      assert %{clients_started: 100} = Db.Simulation.get(id)
    end
  end

  describe "update_session/3" do
    setup :start_server

    test "updates session in Db", %{session: %{id: id}, server: server} do
      assert :ok = State.update_session(server, id, clients_started: 50)

      wait_for_cast()
      assert %{clients_started: 50} = Db.Session.get(id)
    end
  end

  defp start_server(%{simulation: %{id: id}}) do
    {:ok, pid} = start_supervised({StateServer, [id, self()]})

    {:ok, server: pid}
  end
  defp wait_for_cast do
    :timer.sleep(10)
  end
end
