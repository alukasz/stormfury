defmodule Storm.Simulation.LoadBalancerServerTest do
  use ExUnit.Case, async: true

  import Mox

  alias Storm.Simulation
  alias Storm.Simulation.LoadBalancerServer
  alias Storm.Simulation.LoadBalancerServer.State
  alias Storm.Mock.Fury

  setup do
    state = %State{nodes: [:nonode]}
    simulation = %Simulation{id: make_ref()}

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
      assert LoadBalancerServer.init([:nonode]) == {:ok, state}
    end
  end

  describe "handle_call({:start_clients, session_id, ids}, _, _)" do
    test "replies :ok", %{state: state} do
      assert {:reply, :ok, _} =
        LoadBalancerServer.handle_call({:start_clients, :id, 1..10}, :from, state)
    end

    test "adds clients for session to to_start", %{state: state} do
      message = {:start_clients, :id, 1..10}

      {_, _, state} = LoadBalancerServer.handle_call(message, :from, state)

      assert %{to_start: %{id: [1..10]}} = state
    end

    test "appends clients to start for session", %{state: state} do
      state = %{state | to_start: %{id: [1..10]}}
      message = {:start_clients, :id, 11..20}

      {_, _, state} = LoadBalancerServer.handle_call(message, :from, state)

      assert %{to_start: %{id: [1..10, 11..20]}} = state
    end
  end

  describe "handle_info(:do_start_clients, _)" do
    setup do
      {:ok, agent} = start_supervised({Agent, fn -> {%{}, %{}} end})

      {:ok, agent: agent}
    end

    test "does not reply", %{state: state} do
      stub Fury, :start_clients, fn _, _, _ -> :ok end
      state = %{state | to_start: %{id1: [1..10, 11..20], id2: [1..20]}}
      state = %{state | nodes: [1, 2, 3, 4, 5]}

      {:noreply, _} = LoadBalancerServer.handle_info(:do_start_clients, state)
    end

    test "invokes FuryBridge to start clients", %{state: state} do
      expect Fury, :start_clients, fn _, _, _ -> :ok end
      state = %{state | to_start: %{session: [1..10]}}

      {:noreply, _} = LoadBalancerServer.handle_info(:do_start_clients, state)

      verify!()
    end

    test "does not invokes FuryBridge when no clients", %{state: state} do
      stub Fury, :start_clients, fn _, _, _ -> send(self(), :called)end
      state = %{state |to_start: %{}}

      {:noreply, _} = LoadBalancerServer.handle_info(:do_start_clients, state)

      refute_receive _
    end

    test "no clients to start", %{state: state, agent: agent} do
      stub_fury(agent)
      state = %{state | to_start: %{}}

      LoadBalancerServer.handle_info(:do_start_clients, state)

      assert get_nodes(agent) == %{}
      assert get_sessions(agent) == %{}
    end

    test "starts clients from sessions", %{state: state, agent: agent} do
      stub_fury(agent)
      state = %{state | to_start: %{s1: [1..10], s2: [1..40, 1..20]}}

      LoadBalancerServer.handle_info(:do_start_clients, state)

      assert started_sessions(agent) == [s1: 10, s2: 40]
    end

    test "returns state.to_start without started sessions", %{state: state} do
      stub Fury, :start_clients, fn _, _, _ -> :ok end
      state = %{state | to_start: %{s1: [1..5], s2: [1..40, 1..20]}}

      assert {_, %{to_start: %{s2: [1..20]}}} =
        LoadBalancerServer.handle_info(:do_start_clients, state)
    end

    started_clients_per_node = [
      [30],
      [15, 15],
      [10, 10, 10],
      [8, 8, 7, 7],
      [6, 6, 6, 6, 6],
      [5, 5, 5, 5, 5, 5],
      [5, 5, 4, 4, 4, 4, 4],
      [4, 4, 4, 4, 4, 4, 3, 3],
      [4, 4, 4, 3, 3, 3, 3, 3, 3],
      [3, 3, 3, 3, 3, 3, 3, 3, 3, 3]
    ]

    Enum.each started_clients_per_node, fn per_node ->
      test "splits clients between #{length(per_node)} nodes",
          %{state: state, agent: agent} do
        stub_fury(agent)
        nodes = for i <- 1..length(unquote(per_node)), do: :"n#{i}"
        state = %{state | nodes: nodes, to_start: %{s1: [1..10], s2: [1..20]}}

        LoadBalancerServer.handle_info(:do_start_clients, state)

        started = started_nodes(agent)
        expected = Enum.zip(nodes, unquote(per_node))
        Enum.each started, fn node ->
          assert node in expected, "expected: #{inspect expected}\n" <>
            "started:  #{inspect started}"
        end
      end
    end

    defp stub_fury(agent) do
      stub Fury, :start_clients, fn node, session, clients ->
        updater = &Enum.concat(&1, clients)
        Agent.update agent, fn {nodes, sessions}->
          nodes = Map.update(nodes, node, clients, updater)
          sessions = Map.update(sessions, session, clients, updater)

          {nodes, sessions}
        end
      end
    end

    defp started_sessions(agent) do
      agent
      |> get_sessions()
      |> count_started_clients()
    end

    defp started_nodes(agent) do
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
