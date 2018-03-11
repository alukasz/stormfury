defmodule Fury.SessionServerTest do
  use ExUnit.Case, async: true

  import Mox

  alias Fury.SessionServer
  alias Fury.Mock.{Protocol, Storm, Transport}

  describe "start_link/1" do
    test "starts new SessionServer" do
      opts = [make_ref(), "localhost", Transport, Protocol]

      assert {:ok, pid} = SessionServer.start_link(opts)
      assert is_pid(pid)
    end
  end

  describe "get_url/1" do
    setup :start_server

    test "returns url", %{session: id} do
      assert SessionServer.get_url(id) == "localhost"
    end
  end

  describe "get_request/2" do
    setup :start_server

    test "returns request", %{session: id} do
      stub Storm, :get_request, fn _, _ -> {:ok, {:think, 10}} end

      assert SessionServer.get_request(id, 0) == {:ok, {:think, 10}}
    end

    test "invokes StormBridge.get_request/2", %{session: id} do
      expect Storm, :get_request, fn ^id, 0 -> {:ok, {:think, 10}} end

      SessionServer.get_request(id, 0)

      verify!()
    end
  end

  defp start_server(_) do
    id = make_ref()
    opts = [id, "localhost", Transport, Protocol]
    {:ok, pid} = start_supervised({SessionServer, opts})
    allow(Storm, self(), pid)

    {:ok, session: id}
  end
end
