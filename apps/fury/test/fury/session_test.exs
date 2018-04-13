defmodule Fury.SessionTest do
  use ExUnit.Case

  alias Fury.Session
  alias Fury.Session.SessionServer

  setup do
    session = %Session{
      id: make_ref(),
      scenario: "think 10",
      simulation_id: make_ref()
    }

    {:ok, session: session}
  end

  describe "name/1" do
    test "returns :via tuple for name registration" do
      assert Session.name(:id) ==
        {:via, Registry, {Fury.Registry.Session, :id}}
    end
  end

  describe "get_requets/2" do
    setup :start_state_server
    setup :start_server

    test "returns request", %{session: %{id: id}} do
      assert Session.get_request(id, 0) == {:think, 10}
    end
  end

  defp start_state_server(%{session: %{simulation_id: id}}) do
    {:ok, _} = start_supervised({Fury.State.StateServer, id})

    :ok
  end

  defp start_server(%{session: session}) do
    {:ok, pid} = Supervisor.start_link([], strategy: :one_for_one)
    session = %{session | supervisor_pid: pid}
    {:ok, _} = start_supervised({SessionServer, session})

    :ok
  end
end
