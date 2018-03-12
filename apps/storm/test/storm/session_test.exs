defmodule Storm.SessionTest do
  use ExUnit.Case, async: true

  alias Storm.Session
  alias Storm.SessionServer

  setup do
    state = %Session{
      id: make_ref(),
      scenario: [push: "data", think: 10]
    }
    simulation_id = make_ref()
    {:ok, _} = start_supervised({Storm.SessionSupervisor, simulation_id})

    {:ok, state: state, simulation_id: simulation_id}
  end

  describe "new/2" do
    test "starts new SessionServer", %{simulation_id: id, state: state} do
      assert {:ok, pid} = Session.new(id, state)
      assert [{^pid, _}] =
        Registry.lookup(Storm.Session.Registry, state.id)
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
