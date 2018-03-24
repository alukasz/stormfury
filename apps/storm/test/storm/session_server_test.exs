defmodule Storm.SessionServerTest do
  use ExUnit.Case, async: true

  import Mox

  alias Storm.SessionServer
  alias Storm.SessionServer.State
  alias Storm.Simulation.LoadBalancerServer
  alias Storm.Mock.Fury

  setup do
    session = %Db.Session{
      id: make_ref(),
      clients: 10,
      arrival_rate: 2,
      scenario: [push: "data", think: 10],
      simulation_id: make_ref()
    }
    state = %State{
      session: session,
    }

    {:ok, session: session, state: state}
  end

  describe "start_link/1" do
    test "starts new SessionServer", %{session: session} do
      assert {:ok, pid} = SessionServer.start_link(session)
      assert [{^pid, _}] = Registry.lookup(Storm.Session.Registry, session.id)
    end
  end

  describe "name/1" do
    test "returns :via tuple for name registration" do
      assert SessionServer.name(:id) ==
        {:via, Registry, {Storm.Session.Registry, :id}}
    end
  end

  describe "init/1" do
    test "initializes state", %{session: session, state: state} do
      assert SessionServer.init(session) == {:ok, state}
    end
  end

  describe "handle_call({:get_request, index}, _, _)" do
    test "replies with request for given id", %{state: state} do
      assert SessionServer.handle_call({:get_request, 0}, :from, state) ==
        {:reply, {:ok, {:push, "data"}}, state}
    end

    test "replies with error when request not found", %{state: state} do
      assert SessionServer.handle_call({:get_request, 2}, :from, state) ==
        {:reply, {:error, :not_found}, state}
    end
  end

  describe "handle_info(:start_clients, _)" do
    setup %{session: %{simulation_id: id}} do
      simulation = %Db.Simulation{id: id}
      {:ok, _} = start_supervised({Storm.SimulationServer, simulation})
      {:ok, lb} = start_supervised({LoadBalancerServer, %{simulation | hosts: [:nohost]}})

      {:ok, lb: lb}
    end

    test "starts arrival_rate clients",
        %{state: state, lb: lb, session: %{id: id}} do
      allow(Fury, self(), lb)
      expect Fury, :start_clients, fn :"fury@nohost", ^id, [_, _] -> :ok end

      SessionServer.handle_info(:start_clients, state)

      wait_for_lb(lb)
      verify!()
    end

    test "when less than arrival rate",
      %{state: state, lb: lb, session: %{id: id}} do
      allow(Fury, self(), lb)
      expect Fury, :start_clients, fn :"fury@nohost", ^id, [_] -> :ok end
      state = %{state | clients_started: 9}

      SessionServer.handle_info(:start_clients, state)

      wait_for_lb(lb)
      verify!()
    end

    test "does not start clients when all started", %{state: state, lb: lb} do
      allow(Fury, self(), lb)
      stub Fury, :start_clients, fn _, _, _ -> send(self(), :called) end
      state = %{state | clients_started: 10}

      SessionServer.handle_info(:start_clients, state)

      refute_receive _
    end

    defp wait_for_lb(lb) do
      send(lb, :start_clients)
      :timer.sleep(50)
    end
  end
end
