defmodule Fury.SessionServerTest do
  use ExUnit.Case, async: true

  import Mox

  alias Fury.SessionServer
  alias Fury.Mock.{Protocol, Storm, Transport}

  setup do
    state = %SessionServer.State{
      id: make_ref(),
      url: "localhost",
    }

    {:ok, state: state}
  end

  describe "start_link/1" do
    test "starts new SessionServer" do
      id = make_ref()
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

  describe "handle_call(:get_url, _, _)" do
    test "returns url", %{state: state} do
      assert SessionServer.handle_call(:get_url, :from, state) ==
        {:reply, "localhost", state}
    end
  end

  describe "handle_call({:get_request, id}, _, _)" do
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
  end
end
