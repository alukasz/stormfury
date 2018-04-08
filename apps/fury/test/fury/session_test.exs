defmodule Fury.SessionTest do
  use ExUnit.Case

  import Mox

  alias Fury.Client
  alias Fury.Session
  alias Fury.Simulation
  alias Fury.Session.SessionServer
  alias Fury.Mock.Transport

  setup do
    simulation_id = make_ref()
    session = %Session{
      id: make_ref(),
      scenario: "think 10",
      simulation_id: simulation_id
    }
    simulation = %Simulation{
      id: simulation_id,
      sessions: [session],
      protocol_mod: Fury.Protocol.Noop,
      transport_mod: Fury.Mock.Transport
    }

    {:ok, simulation: simulation, session: session}
  end

  describe "name/1" do
    test "returns :via tuple for name registration" do
      assert Session.name(:id) ==
        {:via, Registry, {Fury.Registry.Session, :id}}
    end
  end

  describe "get_requets/2" do
    setup :start_config_server
    setup :start_server

    test "returns request", %{session: %{id: id}} do
      assert Session.get_request(id, 0) == {:think, 10}
    end
  end

  describe "start_clients" do
    setup :start_config_server
    setup :start_client_supervisor
    setup :start_server
    setup :set_mox_global
    setup do
      stub Transport, :connect, fn _, _ -> {:error, :timeout} end

      :ok
    end

    test "starts clients", %{session: %{id: id},
                             simulation: %{id: simulation_id}} do
      assert :ok = Session.start_clients(id, [1, 2, 3])

      :timer.sleep(50)
      clients =
        simulation_id
        |> Client.supervisor_name()
        |> DynamicSupervisor.which_children()

      assert length(clients) == 3
    end
  end

  defp start_config_server(%{simulation: simulation}) do
    {:ok, _} = start_supervised({Fury.Simulation.ConfigServer, simulation})

    :ok
  end

  defp start_server(%{simulation: %{id: simulation_id}, session: %{id: id}}) do
    opts = [start: {SessionServer, :start_link, [simulation_id, id]}]
    {:ok, _} = start_supervised(SessionServer, opts)

    :ok
  end

  defp start_client_supervisor(%{simulation: %{id: id}}) do
    {:ok, _} = start_supervised({Fury.Client.ClientSupervisor, id})

    :ok
  end
end
