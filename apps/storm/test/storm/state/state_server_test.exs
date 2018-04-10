defmodule Storm.State.StateServerTest do
  use ExUnit.Case, async: true

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

  describe "start_link/1" do
    setup :insert_simulation

    test "initializes state", %{simulation: simulation} do
      assert {:ok, pid} =  StateServer.start_link([simulation.id, self()])
      assert is_pid(pid)
    end
  end

  describe "init/1" do
    setup :insert_simulation

    test "initializes state", %{simulation: simulation, state: state} do
      assert StateServer.init([simulation.id, self()]) == {:ok, state}
    end
  end

  describe "handle_call :get_simulation_state" do
    test "returns state for simulation", %{state: state} do
      assert {:reply, simulation, ^state} =
        StateServer.handle_call(:get_simulation_state, :from, state)
      assert %Storm.Simulation{sessions: [%Storm.Session{}]} = simulation
    end
  end

  describe "handle_call {:get_session_state, id}" do
    test "returns state for session", %{state: state, session: %{id: id}} do
      assert {:reply, %Storm.Session{id: ^id}, ^state} =
        StateServer.handle_call({:get_session_state, id}, :from, state)
    end
  end

  defp insert_simulation(%{simulation: simulation}) do
    :ok = Db.Simulation.insert(simulation)

    :ok
  end
end
