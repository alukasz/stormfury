defmodule Fury.Session.SessionServerTest do
  use ExUnit.Case

  import Mox

  alias Fury.Session
  alias Fury.Session.SessionServer
  alias Fury.Cache
  alias Fury.State
  alias Fury.Mock.Transport

  setup do
    simulation_id = make_ref()
    session = %Session{
      id: make_ref(),
      scenario: "think 10",
      simulation_id: simulation_id,
      protocol_mod: Fury.Protocol.Noop,
      transport_mod: Fury.Mock.Transport
    }
    simulation = %{
      id: simulation_id,
    }

    {:ok, simulation: simulation, session: session, session: session}
  end

  describe "start_link/1" do
    setup :start_state_server
    setup %{session: session} do
      {:ok, pid} = Supervisor.start_link([], strategy: :one_for_one)

      {:ok, session: %{session | supervisor_pid: pid}}
    end

    test "starts new SessionServer", %{session: session} do
      {:ok, pid} = SessionServer.start_link(session)

      assert [{^pid, _}] = Registry.lookup(Fury.Registry.Session, session.id)
    end
  end

  describe "init/1" do
    test "builds requests cache", %{session: session} do
      assert {:ok, %{requests_cache: cache}} = SessionServer.init(session)

      assert Cache.get(cache, 0) == {:ok, {:think, 10}}
    end

    test "appends requests list with :done", %{session: session} do
      assert {:ok, %{requests_cache: cache}} = SessionServer.init(session)

      assert Cache.get(cache, 1) == {:ok, :done}
    end

    test "sends message to start ClientsSupervisor", %{session: session} do
      SessionServer.init(session)

      assert_receive :start_clients_supervisor
    end
  end

  describe "handle_call {:get_request, id}" do
    setup :start_state_server
    setup %{session: session} do
      cache = Cache.new(:requests_cache)
      Cache.put(cache, 0, {:think, 10})
      Cache.put(cache, 1, :done)

      {:ok, session: %{session | requests_cache: cache}}
    end

    test "replies with request", %{session: session} do
      assert SessionServer.handle_call({:get_request, 0}, self(), session) ==
        {:reply, {:think, 10}, session}
    end

    test "replies with :error when request not found", %{session: session} do
      assert SessionServer.handle_call({:get_request, 1_000}, self(), session) ==
        {:reply, :error, session}
    end
  end

  describe "handle_cast {:start_clients, ids}" do
    setup :start_state_server
    setup :start_clients_supervisor
    setup :set_mox_global
    setup do
      stub Transport, :connect, fn _ -> {:error, :timeout} end

      :ok
    end

    test "starts clients", %{session: session} do
      SessionServer.handle_cast({:start_clients, [1, 2]}, session)

      clients = DynamicSupervisor.which_children(session.clients_sup_pid)
      assert length(clients) == 2
    end

    test "does not change state", %{session: session} do
      assert SessionServer.handle_cast({:start_clients, [1, 2]}, session) ==
        {:noreply, session}
    end

    test "adds started ids to State", %{session: session} do
      SessionServer.handle_cast({:start_clients, [1, 2]}, session)

      assert State.get_ids(session.simulation_id, session.id) == [1, 2]
    end
  end

  defp start_state_server(%{simulation: %{id: id}}) do
    {:ok, _} = start_supervised({Fury.State.StateServer, id})

    :ok
  end

  defp start_clients_supervisor(%{session: session}) do
    {:ok, pid} = start_supervised(Fury.Client.ClientsSupervisor)

    {:ok, session: %{session | clients_sup_pid: pid}}
  end
end
