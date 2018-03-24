defmodule Storm.Simulation.LoadBalancerServerTest do
  use ExUnit.Case, async: true

  import Mox

  alias Storm.Simulation.LoadBalancerServer
  alias Storm.Simulation.LoadBalancerServer.State
  alias Storm.Mock.Fury

  setup do
    state = %State{nodes: [:nonode]}
    simulation = %Db.Simulation{id: make_ref()}

    {:ok, state: state, simulation: simulation}
  end

  describe "start_link/1" do
    test "starts new LoadBalancerServer", %{simulation: simulation} do
      assert {:ok, pid} = LoadBalancerServer.start_link(simulation)
      assert [{^pid, _}] =
        Registry.lookup(Storm.LoadBalancer.Registry, simulation.id)
    end
  end

  describe "name/1" do
    test "returns :via tuple for name registration" do
      assert LoadBalancerServer.name(:id) ==
        {:via, Registry, {Storm.LoadBalancer.Registry, :id}}
    end
  end

  describe "init/1" do
    test "initializes state", %{state: state} do
      assert LoadBalancerServer.init([:nonode]) == {:ok, %{state | nodes: [:"fury@nonode"]}}
    end
  end

  describe "handle_call({:start_clients, session_id, ids}, _, _)" do
    test "replies :ok", %{state: state} do
      assert {:reply, :ok, _} =
        LoadBalancerServer.handle_call({:add_clients, []}, :from, state)
    end

    test "adds clients state.to_start", %{state: state} do
      message = {:add_clients, id: 1, id: 2}

      {_, _, state} = LoadBalancerServer.handle_call(message, :from, state)

      assert %{to_start: [id: 1, id: 2]} = state
    end

    test "append clients existing clients in state.to_start", %{state: state} do
      state = %{state | to_start: [id1: 1, id1: 2]}
      message = {:add_clients, id2: 1, id2: 2}

      {_, _, state} = LoadBalancerServer.handle_call(message, :from, state)

      assert %{to_start: [id1: 1, id1: 2, id2: 1, id2: 2]} = state
    end
  end

  describe "handle_info(:start_clients, _)" do
    setup do
      {:ok, agent} = start_supervised({Agent, fn -> {%{}, %{}} end})

      {:ok, agent: agent}
    end

    test "does not reply", %{state: state} do
      stub Fury, :start_clients, fn _, _, _ -> :ok end

      assert {:noreply, _} =
        LoadBalancerServer.handle_info(:start_clients, state)
    end

    test "invokes FuryBridge to start clients", %{state: state} do
      expect Fury, :start_clients, fn _, _, _ -> :ok end
      state = %{state | to_start: [s1: 1]}

      {:noreply, _} = LoadBalancerServer.handle_info(:start_clients, state)

      verify!()
    end

    test "does not invokes FuryBridge when no clients", %{state: state} do
      stub Fury, :start_clients, fn _, _, _ -> send(self(), :called) end

      LoadBalancerServer.handle_info(:start_clients, state)

      refute_receive _
    end

    test "returns empty state.to_start", %{state: state} do
      stub Fury, :start_clients, fn _, _, _ -> :ok end
      state = %{state | to_start: [s1: 1, s2: 1]}

      assert {_, %{to_start: []}} =
        LoadBalancerServer.handle_info(:start_clients, state)
    end

    test "no clients to start", %{state: state, agent: agent} do
      track_started_clients(agent)
      state = %{state | to_start: []}

      LoadBalancerServer.handle_info(:start_clients, state)

      assert started_per_session(agent) == []
    end

    test "starts clients from sessions", %{state: state, agent: agent} do
      track_started_clients(agent)
      state = %{state | to_start: [s1: 1, s1: 2, s2: 1, s2: 2, s2: 3]}

      LoadBalancerServer.handle_info(:start_clients, state)

      assert started_per_session(agent) == [s1: 2, s2: 3]
    end

    @started_clients_per_node Enum.with_index([
      30..30, 15..15, 10..10, 7..8, 6..6,
      5..5, 4..5, 4..3, 4..3, 3..3
    ], 1)

    Enum.each @started_clients_per_node, fn {range, nodes} ->
      test "splits clients between #{nodes} nodes",
          %{state: state, agent: agent} do
        track_started_clients(agent)
        nodes = for i <- 1..unquote(nodes), do: :"n#{i}"
        to_start = List.duplicate({:session, 1}, 30)
        state = %{state | nodes: nodes, to_start: to_start}

        LoadBalancerServer.handle_info(:start_clients, state)

        Enum.each started_per_node(agent), fn {_, amount} ->
          assert amount in unquote(Macro.escape(range))
        end
      end
    end

    defp track_started_clients(agent) do
      stub Fury, :start_clients, fn node, session, clients ->
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
end
