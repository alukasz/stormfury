defmodule Fury.SessionTest do
  use ExUnit.Case, async: true

  import Mox

  alias Fury.Session
  alias Fury.SessionServer
  alias Fury.ClientSupervisor
  alias Fury.Mock.{Protocol, Storm, Transport}

  describe "new/4" do
    test "starts new SessionServer" do
      assert {:ok, pid} =
        Session.new(make_ref(), "localhost", Transport, Protocol)
      assert is_pid(pid)
    end
  end

  describe "start_clients/2" do
    setup :start_server
    setup :terminate_clients
    setup :set_mox_global

    test "starts clients", %{session: id} do
      stub Protocol, :init, fn -> %{} end
      stub Transport, :connect, fn _, _ -> {:error, :timeout} end

      :ok = Session.start_clients(id, [1, 2, 3])

      assert length(DynamicSupervisor.which_children(ClientSupervisor)) == 3
    end
  end

  describe "get_request/2" do
    setup :start_server

    test "returns request", %{session: id} do
      stub Storm, :get_request, fn _, _ -> {:ok, {:think, 10}} end

      assert Session.get_request(id, 0) == {:ok, {:think, 10}}
    end

    test "invokes StormBridge.get_request/2", %{session: id} do
      expect Storm, :get_request, fn ^id, 0 -> {:ok, {:think, 10}} end

      Session.get_request(id, 0)

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

  defp terminate_clients(_) do
    ClientSupervisor
    |> DynamicSupervisor.which_children()
    |> Enum.each(fn {_, pid, _, _} ->
      DynamicSupervisor.terminate_child(ClientSupervisor, pid)
    end)
  end
end
