defmodule Storm.SessionTest do
  use ExUnit.Case, async: true

  alias Storm.Session
  alias Storm.SessionServer

  setup do
    session = %Db.Session{
      id: make_ref(),
      simulation_id: make_ref(),
      scenario: [push: "data", think: 10]
    }
    simulaion = %Db.Simulation{id: session.simulation_id}
    {:ok, _} = start_supervised({Storm.SessionSupervisor, simulaion})

    {:ok, session: session}
  end

  describe "new/1" do
    test "starts new SessionServer", %{session: %{id: id} = session} do
      assert {:ok, pid} = Session.new(session)
      assert [{^pid, _}] = Registry.lookup(Storm.Session.Registry, id)
    end
  end

  describe "get_request/2" do
    setup %{session: session} do
      {:ok, _} = start_supervised({SessionServer, session})

      :ok
    end

    test "returns request session id and index",
        %{session: %{id: session_id}} do
      assert Session.get_request(session_id, 0) == {:ok, {:push, "data"}}
      assert Session.get_request(session_id, 1) == {:ok, {:think, 10}}
    end

    test "returns error tuple when request not found",
        %{session: %{id: session_id}} do
      assert Session.get_request(session_id, 10) == {:error, :not_found}
    end
  end
end
