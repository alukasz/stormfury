defmodule Fury.Session.SessionServerTest do
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
      simulation_id: simulation_id,
    }
    simulation = %Simulation{
      id: simulation_id,
      sessions: [session],
      protocol_mod: Fury.Protocol.Noop,
      transport_mod: Fury.Mock.Transport
    }

    {:ok, simulation: simulation, session: session, session: session}
  end

  describe "start_link/1" do
    setup :start_config_server

    test "starts new SessionServer",
        %{simulation: %{id: simulation_id}, session: %{id: session_id}} do
      {:ok, pid} = SessionServer.start_link(simulation_id, session_id)

      assert [{^pid, _}] = Registry.lookup(Fury.Registry.Session, session_id)
    end
  end

  describe "init/1" do
    setup :start_config_server

    test "initializes state", %{simulation: %{id: simulation_id},
                                session: %{id: session_id} = session} do
      assert SessionServer.init([simulation_id, session_id]) == {:ok, session}
    end

    test "sends message to parse scenario",
      %{simulation: %{id: simulation_id}, session: %{id: session_id}} do

      SessionServer.init([simulation_id, session_id])

      assert_receive :parse_scenario
    end
  end

  describe "handle_call({:get_request, id}, state)" do
    setup %{session: session} do
      requests = [{:think, 10}, :done]

      {:ok, session: %{session | requests: requests}}
    end

    test "replies with request", %{session: session} do
      assert SessionServer.handle_call({:get_request, 0}, self(), session) ==
        {:reply, {:think, 10}, session}
    end

    test "replies with :error when request not found", %{session: session} do
      assert SessionServer.handle_call({:get_request, 1_000}, self(), session) ==
        {:reply, :error, session}
    end
  end

  describe "handle_info(:parse_scenario, state)" do
    test "builds requests from scenario", %{session: session} do
      assert {:noreply, %{requests: [{:think, 10}, :done]}} =
        SessionServer.handle_info(:parse_scenario, session)
    end
  end

  describe "handle_cast({:start_clients, ids}, state)" do
    setup :start_config_server
    setup :start_client_supervisor
    setup :set_mox_global
    setup do
      stub Transport, :connect, fn _, _ -> {:error, :timeout} end

      :ok
    end

    test "starts clients", %{session: session, simulation: %{id: id}} do
      SessionServer.handle_call({:start_clients, [1, 2]}, :from, session)

      clients =
        id
        |> Client.supervisor_name()
        |> DynamicSupervisor.which_children()

      assert length(clients) == 2
    end

    test "does not change state", %{session: session} do
      msg = {:start_clients, [1, 2]}

      assert SessionServer.handle_call(msg, :from, session) ==
        {:reply, :ok, session}
    end
  end

  defp start_config_server(%{simulation: simulation}) do
    {:ok, _} = start_supervised({Fury.Simulation.ConfigServer, simulation})

    :ok
  end

  defp start_client_supervisor(%{simulation: %{id: id}}) do
    {:ok, _} = start_supervised({Fury.Client.ClientSupervisor, id})

    :ok
  end
end
