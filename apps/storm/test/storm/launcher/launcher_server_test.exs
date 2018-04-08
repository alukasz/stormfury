defmodule Storm.Launcher.LauncherServerTest do
  use ExUnit.Case, async: true

  import Mox

  alias Storm.Dispatcher.DispatcherServer
  alias Storm.Launcher.LauncherServer
  alias Storm.Simulation.SimulationServer
  alias Storm.Mock

  setup do
    simulation_id = make_ref()
    session = %Db.Session{
      id: make_ref(),
      clients: 10,
      arrival_rate: 2,
      simulation_id: simulation_id
    }
    Db.Session.insert(session)

    {:ok, session: session, simulation_id: simulation_id}
  end

  describe "start_link/2" do
    test "starts new LauncherServer", %{session: %{id: session_id}} do
      assert {:ok, pid} = LauncherServer.start_link(session_id)
      assert is_pid(pid)
    end
  end

  describe "init/1" do
    test "initializes state", %{session: session} do
      assert LauncherServer.init(session.id) == {:ok, session}
    end

    test "restores state from Db", %{session: session} do
      Db.Session.update(session, clients_started: 20)
      assert {:ok, %{clients_started: 20}} = LauncherServer.init(session.id)
    end
  end
  describe "handle_info(:start_clients, _)" do
    setup :create_pg2_group
    setup :start_simulation_server
    setup :start_dispatcher_server

    test "starts arrival_rate clients", %{session: session, dispatcher: dispatcher} do
      allow(Mock.Fury, self(), dispatcher)
      expect Mock.Fury, :start_clients, fn _, _, [_, _] -> :ok end

      LauncherServer.handle_info(:start_clients, session)

      wait_for_dispatcher(dispatcher)
      verify!()
    end

    test "when less than arrival rate",
        %{dispatcher: dispatcher, session: session} do
      allow(Mock.Fury, self(), dispatcher)
      expect Mock.Fury, :start_clients, fn _, _, [_] -> :ok end
      session = %{session | clients_started: 9}

      LauncherServer.handle_info(:start_clients, session)

      wait_for_dispatcher(dispatcher)
      verify!()
    end

    test "does not start clients when all started",
        %{dispatcher: dispatcher, session: session} do
      allow(Mock.Fury, self(), dispatcher)
      stub Mock.Fury, :start_clients, fn _, _, _ -> send(self(), :called) end
      session = %{session | clients_started: 10}

      LauncherServer.handle_info(:start_clients, session)

      refute_receive _
    end

    test "updated Db.Session", %{dispatcher: dispatcher, session: session} do
      allow(Mock.Fury, self(), dispatcher)
      stub Mock.Fury, :start_clients, fn _, _, _ -> :ok end
      session = %{session | clients_started: 5}

      LauncherServer.handle_info(:start_clients, session)

      assert %{clients_started: 7} = Db.Session.get(session.id)
    end

    defp wait_for_dispatcher(dispatcher) do
      send(dispatcher, :start_clients)
      :timer.sleep(50)
    end

    defp start_simulation_server(%{simulation_id: id, session: session}) do
      fake_launcher_server(session)
      simulation = %Db.Simulation{id: id, duration: 1}
      :ok = Db.Repo.insert(simulation)
      {:ok, pid} = start_supervised({SimulationServer, simulation})
      stub Mock.Fury, :start_simulation, fn _ -> {[], []} end
      allow(Mock.Fury, self(), pid)

      :ok
    end

    defp fake_launcher_server(%{id: id}) do
      spawn_link fn ->
        Registry.register(Storm.Registry.Launcher, id, nil)
        :timer.sleep(1_000)
      end
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
