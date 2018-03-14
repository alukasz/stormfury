defmodule Storm.SessionServerTest do
  use ExUnit.Case, async: true

  alias Storm.Session
  alias Storm.SessionServer

  setup do
    state = %Session{
      id: make_ref(),
      clients: 10,
      arrival_rate: 1,
      scenario: [push: "data", think: 10]
    }

    {:ok, state: state}
  end

  describe "start_link/1" do
    test "starts new SessionServer", %{state: state} do
      assert {:ok, pid} = SessionServer.start_link(state)
      assert is_pid(pid)
    end
  end

  describe "name/1" do
    test "returns :via tuple for name registration" do
      assert SessionServer.name(:id) ==
        {:via, Registry, {Storm.Session.Registry, :id}}
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
end
