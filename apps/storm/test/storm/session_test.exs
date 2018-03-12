defmodule Storm.SessionTest do
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

  describe "new/4" do
    test "starts new SessionServer", %{state: state} do
      assert {:ok, pid} = Session.new(state)
      assert is_pid(pid)
    end
  end

  describe "get_request/2" do
    setup %{state: %{id: id} = state} do
      {:ok, _} = start_supervised({SessionServer, state})

      {:ok, session: id}
    end

    test "returns request session id and index", %{session: session} do
      assert Session.get_request(session, 0) == {:ok, {:push, "data"}}
      assert Session.get_request(session, 1) == {:ok, {:think, 10}}
    end

    test "returns error tuple when request not found", %{session: session} do
      assert Session.get_request(session, 10) == {:error, :not_found}
    end
  end
end
