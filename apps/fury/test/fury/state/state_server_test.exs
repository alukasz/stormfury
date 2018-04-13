defmodule Fury.State.StateServerTest do
  use ExUnit.Case, async: true

  alias Fury.State.StateServer

  describe "start_link/1" do
    test "starts new State server" do
      id = make_ref()

      assert {:ok, _} = StateServer.start_link(id)

      assert [_] = Registry.lookup(Fury.Registry.State, id)
    end
  end

  describe "init/1" do
    test "initializes state" do
      assert StateServer.init([]) == {:ok, %{}}
    end
  end

  describe "handle_call{:get_ids, session_id}" do
    test "returns ids for a session id" do
      state = %{s1: [1, 2, 3], s2: [4, 5, 6]}
      request = {:get_ids, :s1}

      assert {:reply, [1,2,3], ^state} = StateServer.handle_call(request, :from, state)
    end
  end

  describe "handle_cast {:add_ids, session_id, ids}" do
    test "adds ids under session_id" do
      request = {:add_ids, :session_id, [1, 2, 3]}

      assert {:noreply, %{session_id: [1, 2, 3]}} =
        StateServer.handle_cast(request, %{})
    end

    test "prepends new ids to existing" do
      request = {:add_ids, :session_id, [3, 4]}

      assert {:noreply, %{session_id: [3, 4, 1, 2]}} =
        StateServer.handle_cast(request, %{session_id: [1, 2]})
    end

    test "does not add duplicated ids" do
      request = {:add_ids, :session_id, [1, 2]}

      assert {:noreply, %{session_id: [1, 2]}} =
        StateServer.handle_cast(request, %{session_id: [1, 2]})
    end
  end
end
