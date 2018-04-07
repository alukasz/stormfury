defmodule Storm.Simulation.DispatcherServerTest do
  use ExUnit.Case, async: true

  import Mox

  alias Storm.Dispatcher.DispatcherServer
  alias Storm.Dispatcher.DispatcherServer.State
  alias Storm.Mock

  setup do
    simulation_id = make_ref()
    state = %State{simulation_id: simulation_id}

    {:ok, state: state, simulation_id: simulation_id}
  end

  describe "start_link/1" do
    test "starts new DispatcherServer", %{simulation_id: id} do
      assert {:ok, pid} = DispatcherServer.start_link(id)
      assert [{^pid, _}] = Registry.lookup(Storm.Registry.Dispatcher, id)
    end
  end


  describe "init/1" do
    test "initializes state", %{simulation_id: id, state: state} do
      assert DispatcherServer.init(id) == {:ok, state}
    end
  end

  describe "handle_call({:start_clients, session_id, ids}, _, _)" do
    test "replies :ok", %{state: state} do
      assert {:reply, :ok, _} =
        DispatcherServer.handle_call({:add_clients, []}, :from, state)
    end

    test "adds clients state.to_start", %{state: state} do
      message = {:add_clients, id: 1, id: 2}

      {_, _, state} = DispatcherServer.handle_call(message, :from, state)

      assert %{to_start: [id: 1, id: 2]} = state
    end

    test "append clients existing clients in state.to_start", %{state: state} do
      state = %{state | to_start: [id1: 1, id1: 2]}
      message = {:add_clients, id2: 1, id2: 2}

      {_, _, state} = DispatcherServer.handle_call(message, :from, state)

      assert %{to_start: [id1: 1, id1: 2, id2: 1, id2: 2]} = state
    end
  end

  describe "handle_info(:start_clients, _)" do
    setup do
      {:ok, agent} = start_supervised({Agent, fn -> {%{}, %{}} end})

      {:ok, agent: agent}
    end
    setup :create_pg2_group

    test "does not reply", %{state: state} do
      stub Mock.Fury, :start_clients, fn _, _, _ -> :ok end

      assert {:noreply, _} =
        DispatcherServer.handle_info(:start_clients, state)
    end

    test "invokes Mock.FuryBridge to start clients", %{state: state} do
      expect Mock.Fury, :start_clients, fn _, _, _ -> :ok end
      state = %{state | to_start: [s1: 1]}

      {:noreply, _} = DispatcherServer.handle_info(:start_clients, state)

      verify!()
    end

    test "does not invokes Mock.FuryBridge when no clients", %{state: state} do
      stub Mock.Fury, :start_clients, fn _, _, _ -> send(self(), :called) end

      DispatcherServer.handle_info(:start_clients, state)

      refute_receive _
    end

    test "returns empty state.to_start", %{state: state} do
      stub Mock.Fury, :start_clients, fn _, _, _ -> :ok end
      state = %{state | to_start: [s1: 1, s2: 1]}

      assert {_, %{to_start: []}} =
        DispatcherServer.handle_info(:start_clients, state)
    end

    test "no clients to start", %{state: state, agent: agent} do
      track_started_clients(agent)
      state = %{state | to_start: []}

      DispatcherServer.handle_info(:start_clients, state)

      assert started_per_session(agent) == []
    end

    test "starts clients from sessions", %{state: state, agent: agent} do
      track_started_clients(agent)
      state = %{state | to_start: [s1: 1, s1: 2, s2: 1, s2: 2, s2: 3]}

      DispatcherServer.handle_info(:start_clients, state)

      assert started_per_session(agent) == [s1: 2, s2: 3]
    end

    @started_clients_per_node Enum.with_index([
      30..30, 15..15, 10..10, 7..8, 6..6,
      5..5, 4..5, 4..3, 4..3, 3..3
    ])

    Enum.each @started_clients_per_node, fn {range, pids} ->
      test "splits clients between #{pids + 1} nodes",
          %{state: state, agent: agent, pg2_group: group} do
        track_started_clients(agent)
        start_pg2_processes(group, unquote(pids))

        to_start = List.duplicate({:session, 1}, 30)
        state = %{state | to_start: to_start}

        DispatcherServer.handle_info(:start_clients, state)

        Enum.each started_per_node(agent), fn {_, amount} ->
          assert amount in unquote(Macro.escape(range))
        end
      end
    end

    defp start_pg2_processes(group, number) do
      # compensate for :join in setup create_pg2_group
      :pg2.leave(group, self())
      for _ <- 0..number do
        pid = spawn_link fn -> :timer.sleep(1_000_000) end
        :pg2.join(group, pid)
      end
    end

    defp track_started_clients(agent) do
      stub Mock.Fury, :start_clients, fn node, session, clients ->
        updater = &Enum.concat(&1, clients)
        Agent.update agent, fn {nodes, sessions} ->
          nodes = Map.update(nodes, node, clients, updater)
          sessions = Map.update(sessions, session, clients, updater)

          {nodes, sessions}
        end
      end
    end

    defp started_per_session(agent) do
      agent
      |> get_sessions()
      |> count_started_clients()
    end

    defp started_per_node(agent) do
      agent
      |> get_nodes()
      |> count_started_clients()
    end

    defp get_nodes(agent) do
      Agent.get(agent, &elem(&1, 0))
    end

    defp get_sessions(agent) do
      Agent.get(agent, &elem(&1, 1))
    end

    defp count_started_clients(clients) do
      Enum.map clients, fn {item, clients} ->
        {item, length(clients)}
      end
    end
  end

  defp create_pg2_group(%{simulation_id: simulation_id}) do
    group = Fury.group(simulation_id)
    :pg2.create(group)
    :pg2.join(group, self())

    {:ok, pg2_group: group}
  end
end
