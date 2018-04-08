defmodule Fury.Simulation.SimulationServerTest do
  use ExUnit.Case, async: true

  alias Fury.Simulation
  alias Fury.Simulation.ConfigServer
  alias Fury.Simulation.SimulationServer
  alias Fury.Simulation.SimulationServer.State

  setup do
    simulation = %Simulation{id: make_ref()}

    {:ok, simulation: simulation}
  end

  describe "start_link/1" do
    setup :start_config_server

    test "starts new SimulationServer", %{simulation: %{id: id}} do
      {:ok, _} = SimulationServer.start_link(id)

      assert [_] = Registry.lookup(Fury.Registry.Simulation, id)
    end
  end

  describe "init/1" do
    setup :start_config_server

    test "initializes state", %{simulation: %{id: id} = simulation} do
      state = %State{id: id, simulation: simulation}

      assert SimulationServer.init(id) == {:ok, state}
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
        SimulationServer.handle_call(request, :from, :state)
      end

      assert_receive {:"$gen_call", _, {:start_clients, ^ids}}
    end
  end

  defp start_config_server(%{simulation: simulation}) do
    {:ok, _} = start_supervised({ConfigServer, simulation})

    :ok
  end
end
