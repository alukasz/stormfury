defmodule Fury.SessionTest do
  use ExUnit.Case, async: true

  import Mox

  alias Fury.Session
  alias Fury.SessionServer
  alias Fury.ClientSupervisor
  alias Fury.Mock.{Protocol, Storm, Transport}

  describe "new/4" do
    test "starts new SessionServer" do
      session = %Db.Session{id: :some_id}
      simulation = %Db.Simulation{}

      assert {:ok, pid} = Session.new(session, simulation)
      assert is_pid(pid)
    end
  end

  describe "start_clients/2" do
    setup :start_server
    setup :set_mox_global
    setup :terminate_clients

    test "starts clients", %{session_id: id} do
      stub Protocol, :init, fn -> %{} end
      stub Transport, :connect, fn _, _ -> {:error, :timeout} end

      :ok = Session.start_clients(id, [1, 2, 3])

      assert length(DynamicSupervisor.which_children(ClientSupervisor)) == 3
    end
  end

  describe "get_request/2" do
    setup :start_server
    setup %{server_pid: pid} do
      allow(Storm, self(), pid)
      :ok
    end

    test "returns request", %{session_id: id} do
      stub Storm, :get_request, fn _, _ -> {:ok, {:think, 10}} end

      assert Session.get_request(id, 0) == {:ok, {:think, 10}}
    end

    test "invokes StormBridge.get_request/2", %{session_id: id} do
      expect Storm, :get_request, fn ^id, 0 -> {:ok, {:think, 10}} end

      Session.get_request(id, 0)

      verify!()
    end

    test "uses cache on subsequent calls", %{session_id: id} do
      expect Storm, :get_request, fn _, _ -> {:ok, :data} end
      Session.get_request(id, 1)

      assert Session.get_request(id, 1) == {:ok, :data}
    end
  end

  defp start_server(%{line: line}) do
    id = :"session_test_#{line}"
    session = %Db.Session{id: id}
    simulation = %Db.Simulation{transport_mod: Transport, protocol_mod: Protocol}
    {:ok, pid} = start_supervised({SessionServer, [session, simulation]})

    {:ok, session_id: id, server_pid: pid}
  end

  defp terminate_clients(_) do
    on_exit fn ->
      ClientSupervisor
      |> DynamicSupervisor.which_children()
      |> Enum.each(fn {_, pid, _, _} ->
        DynamicSupervisor.terminate_child(ClientSupervisor, pid)
      end)
    end
  end
end
