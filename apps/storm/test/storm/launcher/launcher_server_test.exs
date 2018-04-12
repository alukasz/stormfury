defmodule Storm.Launcher.LauncherServerTest do
  use ExUnit.Case, async: true

  import Mox
  import Storm.SimulationHelper

  alias Storm.Dispatcher.DispatcherServer
  alias Storm.Launcher.LauncherServer
  alias Storm.Mock

  setup :default_simulation
  setup :default_session
  setup :insert_simulation

  describe "start_link/2" do
    setup :register_self_as_simulation

    test "starts new LauncherServer", %{simulation: %{id: simulation_id},
                                        session: %{id: session_id}} do
      spawn_link fn ->
        assert {:ok, pid} =
          LauncherServer.start_link([simulation_id, session_id])
        assert is_pid(pid)
      end
    end
  end

  describe "init/1" do
    setup :register_self_as_simulation

    test "initializes state", %{simulation: simulation, session: session} do
      spawn_link fn ->
        assert LauncherServer.init([simulation.id, session.id]) ==
          {:ok, session}
      end
    end

    test "restores state from Db", %{simulation: simulation,
                                     session: session} do
      Db.Session.update(session, clients_started: 20)

      spawn_link fn ->
        assert {:ok, %{clients_started: 20}} =
          LauncherServer.init([simulation.id, session.id])
      end
    end
  end

  describe "handle_info(:start_clients, _)" do
    setup :create_pg2_group
    setup :start_simulation_server
    setup :start_dispatcher_server
    setup %{session: session, dispatcher: dispatcher} do
      {:ok, session: %{session | dispatcher_pid: dispatcher}}
    end

    test "starts arrival_rate clients", %{session: session,
                                          dispatcher: dispatcher} do
      allow(Mock.Fury, self(), dispatcher)
      expect Mock.Fury, :start_clients, fn _, _, [_, _] -> :ok end

      LauncherServer.handle_info(:start_clients, session)

      wait_for_dispatcher(dispatcher)
      verify!()
    end

    test "when less than arrival rate", %{dispatcher: dispatcher,
                                          session: session} do
      allow(Mock.Fury, self(), dispatcher)
      expect Mock.Fury, :start_clients, fn _, _, [_] -> :ok end
      session = %{session | clients_started: 9}

      LauncherServer.handle_info(:start_clients, session)

      wait_for_dispatcher(dispatcher)
      verify!()
    end

    test "does not start clients when all started", %{dispatcher: dispatcher,
                                                      session: session} do
      allow(Mock.Fury, self(), dispatcher)
      stub Mock.Fury, :start_clients, fn _, _, _ -> send(self(), :called) end
      session = %{session | clients_started: 10}

      LauncherServer.handle_info(:start_clients, session)

      refute_receive _
    end

    test "updates Db.Session", %{dispatcher: dispatcher, session: session} do
      allow(Mock.Fury, self(), dispatcher)
      stub Mock.Fury, :start_clients, fn _, _, _ -> :ok end
      session = %{session | clients_started: 5}

      LauncherServer.handle_info(:start_clients, session)

      assert %{clients_started: 7} = Db.Session.get(session.id)
    end

    defp start_dispatcher_server(%{simulation: %{id: id}}) do
      {:ok, dispatcher} = start_supervised({DispatcherServer, id})

      {:ok, dispatcher: dispatcher}
    end

    defp wait_for_dispatcher(dispatcher) do
      send(dispatcher, :start_clients)
      :timer.sleep(50)
    end

    defp register_self_as_simulation(%{simulation: %{id: id}}) do
      Registry.register(Storm.Registry.Simulation, id, nil)

      :ok
    end

    defp create_pg2_group(%{simulation: %{id: id}}) do
      group = Fury.group(id)
      :pg2.create(group)
      :pg2.join(group, self())

      {:ok, pg2_group: group}
    end
  end
end
