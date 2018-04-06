defmodule Fury.ClientTest do
  use ExUnit.Case

  import Mox

  alias Fury.Client
  alias Fury.Session
  alias Fury.Simulation
  alias Fury.Mock.{Protocol, Transport}

  setup do
    session = %Session{
      id: make_ref()
    }
    simulation = %Simulation{
      id: make_ref(),
      protocol_mod: Protocol,
      transport_mod: Transport,
      sessions: [session]
    }

    {:ok, simulation: simulation, session: session}
  end

  describe "start/3" do
    setup :start_config_server
    setup :start_client_supervisor
    setup :set_mox_global

    test "starts new ClientServer",
        %{simulation: %{id: simulation_id}, session: %{id: session_id}} do
      stub Protocol, :init, fn -> %{} end

      {:ok, pid} = Client.start(simulation_id, session_id, :id)

      assert is_pid(pid)
    end
  end

  describe "connect/2" do
    setup do
      {:ok, url: "localhost"}
    end

    test "invokes Transport.connect", %{url: url} do
      expect Transport, :connect, fn _, _ -> {:ok, self()} end

      Client.connect(Transport, url)

      verify!()
    end

    test "returns transport pid", %{url: url} do
      stub Transport, :connect, fn _, _ -> {:ok, self()} end

      assert Client.connect(Transport, url) == {:ok, self()}
    end

    test "on error returns error tuple", %{url: url} do
      stub Transport, :connect, fn _, _ -> {:error, :timeout} end

      assert Client.connect(Transport, url) == {:error, :timeout}
    end
  end

  describe "make_request/5" do
    test "invokes Protocol.format/2" do
      expect Protocol, :format, fn _, _ -> {:ok, "data", %{}} end
      stub Transport, :push, fn _, _ -> :ok end

      Client.make_request(Transport, self(), Protocol, %{}, "data")

      verify!()
    end

    test "invokes Transport.push/2" do
      stub Protocol, :format, fn _, _ -> {:ok, "data", %{}} end
      expect Transport, :push, fn _, _ -> :ok end

      Client.make_request(Transport, self(), Protocol, %{}, "data")

      verify!()
    end
  end

  test "returns updated protocol state" do
    stub Protocol, :format, fn _, _ -> {:ok, "data", :updated_state} end
    stub Transport, :push, fn _, _ -> :ok end

    assert Client.make_request(Transport, self(), Protocol, %{}, "data") ==
      :updated_state
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
