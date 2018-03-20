defmodule Fury.SessionServerTest do
  use ExUnit.Case, async: true

  import Mox

  alias Fury.ClientSupervisor
  alias Fury.SessionServer
  alias Fury.Session.Cache
  alias Fury.Mock.{Protocol, Storm, Transport}

  setup %{line: line} do
    state = %SessionServer.State{
      id: :"session_server_test_#{line}",
      url: "localhost",
      transport_mod: Transport,
      protocol_mod: Protocol
    }

    {:ok, state: state}
  end

  describe "start_link/1" do
    test "starts new SessionServer" do
      id = :session_server_test
      opts = [id, "localhost", Transport, Protocol]

      assert {:ok, pid} = SessionServer.start_link(opts)
      assert [{^pid, _}] = Registry.lookup(Fury.Session.Registry, id)
    end
  end

  describe "name/1" do
    test "returns :via tuple for name registration" do
      assert SessionServer.name(:id) ==
        {:via, Registry, {Fury.Session.Registry, :id}}
    end
  end

  describe "handle_call({:start_clients, ids}, _, _)" do
    setup :terminate_clients
    setup :set_mox_global

    test "replies :ok", %{state: state} do
      stub Protocol, :init, fn -> %{} end
      stub Transport, :connect, fn _, _ -> {:error, :timeout} end
      ids = [1, 2, 3]

      assert SessionServer.handle_call({:start_clients, ids}, :from, state) ==
        {:reply, :ok, state}
    end

    test "starts clients", %{state: state} do
      stub Protocol, :init, fn -> %{} end
      stub Transport, :connect, fn _, _ -> {:error, :timeout} end

      SessionServer.handle_call({:start_clients, [1, 2, 3]}, :from, state)

      assert length(DynamicSupervisor.which_children(ClientSupervisor)) == 3
    end
  end

  describe "handle_call({:get_request, id}, _, _)" do
    setup %{state: %{id: id}} do
      Cache.new(id)

      :ok
    end
    test "replies with request", %{state: state} do
      stub Storm, :get_request, fn _, _ -> {:ok, {:think, 10}} end

      assert SessionServer.handle_call({:get_request, 0}, :from, state) ==
        {:reply, {:ok, {:think, 10}}, state}
    end

    test "invokes StormBridge.get_request/2", %{state: state} do
      expect Storm, :get_request, fn _, _ -> {:ok, {:think, 10}} end

      SessionServer.handle_call({:get_request, 0}, :from, state)

      verify!()
    end

    test "stores requests in cache", %{state: state} do
      stub Storm, :get_request, fn _, _ -> {:ok, {:think, 10}} end

      SessionServer.handle_call({:get_request, 0}, :from, state)

      assert Cache.get(state.id, 0) == {:ok, {:think, 10}}
    end
  end

  defp terminate_clients(_) do
    ClientSupervisor
    |> DynamicSupervisor.which_children()
    |> Enum.each(fn {_, pid, _, _} ->
        DynamicSupervisor.terminate_child(ClientSupervisor, pid)
      end)
  end
end