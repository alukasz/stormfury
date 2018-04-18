defmodule Fury.Simulation.SimulationServerTest do
  use ExUnit.Case, async: true

  alias Fury.Simulation.SimulationServer

  setup do
    {:ok, id: make_ref()}
  end

  describe "start_link/1" do
    test "starts new SimulationServer", %{id: id} do
      assert {:ok, pid} = SimulationServer.start_link([id, self()])
      assert is_pid(pid)
    end
  end

  describe "init/1" do
    test "initializes state", %{id: id} do
      state = %{id: id, supervisor_pid: self()}

      assert SimulationServer.init([id, self()]) == {:ok, state}
    end
  end

  describe "handle_call({:start_clients, session_id, ids}, _, _)" do
    setup do
      session_id = make_ref()
      Registry.register(Fury.Registry.Session, session_id, nil)

      {:ok, session_id: session_id}
    end

    test "starts clients in session", %{session_id: session_id} do
      ids = [1, 2, 3]
      request = {:start_clients, session_id, ids}

      spawn fn ->
        assert {:noreply, _} = SimulationServer.handle_cast(request, :state)
      end

      assert_receive {_, {:start_clients, ^ids}}
    end
  end
end
