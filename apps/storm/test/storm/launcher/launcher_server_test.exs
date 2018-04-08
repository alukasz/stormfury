defmodule Storm.Launcher.LauncherServerTest do
  use ExUnit.Case, async: true

  import Mox

  alias Storm.Dispatcher.DispatcherServer
  alias Storm.Launcher.LauncherServer
  alias Storm.Launcher.LauncherServer.State
  alias Storm.Simulation.SimulationServer
  alias Storm.Mock

  setup do
    session = %Db.Session{
      id: make_ref(),
      clients: 10,
      arrival_rate: 2,
    }
    Db.Session.insert(session)
    state = %State{
      simulation_id: make_ref(),
      session: session
    }

    {:ok, session: session, state: state, simulation_id: state.simulation_id}
  end

  describe "start_link/2" do
    test "starts new LauncherServer", %{session: %{id: session_id}} do
      assert {:ok, pid} = LauncherServer.start_link(:id, session_id)
      assert is_pid(pid)
    end
  end

  describe "init/1" do
    test "initializes state", %{state: state, session: %{id: session_id}} do
      opts = [state.simulation_id, session_id]

      assert LauncherServer.init(opts) == {:ok, state}
    end
  end
  describe "handle_info(:start_clients, _)" do
    setup :create_pg2_group
    setup :start_simulation_server
    setup :start_dispatcher_server

    test "starts arrival_rate clients", %{state: state, dispatcher: dispatcher} do
      allow(Mock.Fury, self(), dispatcher)
      expect Mock.Fury, :start_clients, fn _, _, [_, _] -> :ok end

      LauncherServer.handle_info(:start_clients, state)

      wait_for_dispatcher(dispatcher)
      verify!()
    end

    test "when less than arrival rate",
        %{state: state, dispatcher: dispatcher, session: session} do
      allow(Mock.Fury, self(), dispatcher)
      expect Mock.Fury, :start_clients, fn _, _, [_] -> :ok end
      session = %{session | clients_started: 9}
      state = %{state | session: session}

      LauncherServer.handle_info(:start_clients, state)

      wait_for_dispatcher(dispatcher)
      verify!()
    end

    test "does not start clients when all started",
        %{state: state, dispatcher: dispatcher, session: session} do
      allow(Mock.Fury, self(), dispatcher)
      stub Mock.Fury, :start_clients, fn _, _, _ -> send(self(), :called) end
      session = %{session | clients_started: 10}
      state = %{state | session: session}

      LauncherServer.handle_info(:start_clients, state)

      refute_receive _
    end

    defp wait_for_dispatcher(dispatcher) do
      send(dispatcher, :start_clients)
      :timer.sleep(50)
    end

    defp start_simulation_server(%{simulation_id: simulation_id}) do
      simulation = %Db.Simulation{id: simulation_id, duration: 1}
      {:ok, pid} = start_supervised({SimulationServer, simulation})
      stub Mock.Fury, :start_simulation, fn _ -> {[], []} end
      allow(Mock.Fury, self(), pid)

      :ok
    end

    defp start_dispatcher_server(%{simulation_id: simulation_id}) do
      {:ok, dispatcher} = start_supervised({DispatcherServer, simulation_id})

      {:ok, dispatcher: dispatcher}
    end

    defp create_pg2_group(%{simulation_id: simulation_id}) do
      group = Fury.group(simulation_id)
      :pg2.create(group)
      :pg2.join(group, self())

      {:ok, pg2_group: group}
    end
  end
end
