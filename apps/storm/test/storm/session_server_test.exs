defmodule Storm.SessionServerTest do
  use ExUnit.Case, async: true

  alias Storm.SessionServer

  describe "start_link/1" do
    test "starts new SessionServer" do
      assert {:ok, pid} = SessionServer.start_link([make_ref(), 1, 1, []])
      assert is_pid(pid)
    end
  end

  describe "get_request/2" do
    setup do
      id = make_ref()
      scenario = [push: "data", think: 10]

      {:ok, _} = start_supervised({SessionServer, [id, 1, 1, scenario]})

      {:ok, session: id}
    end

    test "returns request session id and index", %{session: session} do
      assert SessionServer.get_request(session, 0) == {:ok, {:push, "data"}}
      assert SessionServer.get_request(session, 1) == {:ok, {:think, 10}}
    end

    test "returns error tuple when request not found", %{session: session} do
      assert SessionServer.get_request(session, 10) == {:error, :not_found}
    end
  end
end
