defmodule Storm.State.StateServerTest do
  use ExUnit.Case, async: true

  import Storm.SimulationHelper

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
      supervisor_pid: self()
    }

    {:ok, simulation: simulation, session: session, state: state}
  end
  setup :insert_simulation

  describe "start_link/1" do
    test "starts StateServer", %{simulation: simulation} do
      assert {:ok, pid} =  StateServer.start_link([simulation.id, self()])
      assert is_pid(pid)
    end
  end

  describe "init/1" do
    test "initializes state", %{simulation: simulation, state: state} do
      assert StateServer.init([simulation.id, self()]) == {:ok, state}
    end

    test "sends message to start simulation server", %{simulation: simulation} do
      StateServer.init([simulation.id, self()])

      assert_receive :start_simulation_server
    end
  end

  describe "handle_call :get_simulation_state" do
    test "returns state for simulation", %{state: state} do
      pid = self()

      assert {:reply, simulation, ^state} =
        StateServer.handle_call(:get_simulation_state, :from, state)
      assert %Storm.Simulation{sessions: [%Storm.Session{}],
                               supervisor_pid: ^pid,
                               state_pid: ^pid} = simulation
    end

    test "fetches simulation from Db", %{simulation: simulation,
                                         state: state} do
      Db.Simulation.update(simulation, clients_started: 10)

      assert {_, %{clients_started: 10}, _} =
        StateServer.handle_call(:get_simulation_state, :from, state)
    end
  end

  describe "handle_call {:get_session_state, id}" do
    test "returns state for session", %{state: state, session: %{id: id}} do
      pid = self()

      assert {:reply, %Storm.Session{id: ^id, state_pid: ^pid}, ^state} =
        StateServer.handle_call({:get_session_state, id}, :from, state)
    end

    test "fetches session from Db", %{session: session, state: state} do
      Db.Session.update(session, clients_started: 5)

      assert {_, %{clients_started: 5}, _} =
        StateServer.handle_call({:get_session_state, session.id}, :from, state)
    end
  end

  describe "handle_cast {:update_simulation, attrs}" do
    test "updates simulation in Db", %{simulation: simulation, state: state} do
      request = {:update_simulation, clients_started: 100}

      assert {:noreply, ^state} = StateServer.handle_cast(request, state)

      assert %{clients_started: 100} = Db.Simulation.get(simulation.id)
    end
  end

  describe "handle_cast {:update_session, id attrs}" do
    test "updates session in Db", %{session: session, state: state} do
      request = {:update_session, session.id, clients_started: 50}

      assert {:noreply, ^state} = StateServer.handle_cast(request, state)

      assert %{clients_started: 50} = Db.Session.get(session.id)
    end
  end

  describe "handle_info :start_simulation_server" do
    test "starts SimulationServer", %{state: state} do
      spawn fn ->
        assert StateServer.handle_info(:start_simulation_server, state)
      end

      assert_receive {_, _, {:start_child, %{id: Storm.Simulation.SimulationServer}}}
    end
  end
end
