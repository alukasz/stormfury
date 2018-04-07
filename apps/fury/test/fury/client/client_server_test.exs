defmodule Fury.Client.ClientServerTest do
  use ExUnit.Case

  import Mox

  alias Fury.Session
  alias Fury.Simulation
  alias Fury.Client.ClientServer
  alias Fury.Client.ClientServer.State
  alias Fury.Session.SessionServer
  alias Fury.Mock.{Protocol, Transport}

  setup :default_structs

  describe "start_link/1" do
    setup :set_mox_global
    setup :start_config_server
    setup do
      stub Protocol, :init, fn -> %{} end

      :ok
    end

    test "starts new ClientServer",
        %{simulation: %{id: simulation_id}, session: %{id: session_id}} do
      {:ok, pid} = ClientServer.start_link(simulation_id, [session_id, :id])

      assert is_pid(pid)
    end
  end

  describe "init/1" do
    setup :start_config_server
    setup %{simulation: %{id: simulation_id}, session: %{id: session_id}} do
      stub Protocol, :init, fn -> %{} end
      init_opts = [simulation_id, session_id, :id]

      {:ok, init_opts: init_opts}
    end

    test "initializes state", %{init_opts: init_opts, state: state} do
      assert ClientServer.init(init_opts) ==
        {:ok, state}
    end

    test "initializes session", %{init_opts: init_opts} do
      expect Protocol, :init, fn -> %{} end

      ClientServer.init(init_opts)

      verify!()
    end

    test "sends message to connect", %{init_opts: init_opts} do
      ClientServer.init(init_opts)

      assert_receive :connect
    end
  end

  describe "handle_info(:connect, state)" do
    test "connects transport", %{state: state} do
      pid = self()
      expect Transport, :connect, fn "localhost", [client: ^pid] ->
        {:ok, pid}
      end

      assert ClientServer.handle_info(:connect, state) ==
        {:noreply, %{state | transport: pid}}

      verify!()
    end

    test "starts making requests when transport connects", %{state: state} do
      stub Transport, :connect, fn _, _ ->
        {:ok, self()}
      end

      ClientServer.handle_info(:connect, state)

      assert_receive :make_request
    end

    test "on error sets transport to :not_connected", %{state: state} do
      pid = self()
      expect Transport, :connect, fn "localhost", [client: ^pid] ->
        {:error, :timeout}
      end

      assert ClientServer.handle_info(:connect, state) ==
        {:noreply, %{state | transport: :not_connected}}

      verify!()
    end

    test "does not make requests on transport error", %{state: state} do
      stub Transport, :connect, fn _, _ ->
        {:error, :timeout}
      end

      ClientServer.handle_info(:connect, state)

      refute_receive :make_request
    end
  end

  describe "handle_info({:transport_data, data}, state)" do
    test "invokes protocol to handle data", %{state: state} do
      expect Protocol, :handle_data, fn "data", %{} ->
        {:ok, :updated_state}
      end

      assert ClientServer.handle_info({:transport_data, "data"}, state) ==
        {:noreply, %{state | protocol_state: :updated_state}}

      verify!()
    end
  end

  describe "handle_info({:transport_disconnected, reason}, state)" do
    test "sets transport to :not_connected", %{state: state} do
      message = {:transport_disconnected, :reason}

      assert ClientServer.handle_info(message, state) ==
        {:noreply, %{state | transport: :not_connected}}
    end
  end

  describe "handle_info({:make_request, id} state)" do
    setup %{state: state} do
      {:ok, state: %{state | transport: self()}}
    end

    test "when request is found increases state.request", %{state: state} = context do
      start_session_server(context, "think 10")
      expected_request_id = state.request + 1

      assert {:noreply, %{request: ^expected_request_id}} =
        ClientServer.handle_info(:make_request, state)
    end

    test "updates state.protocol_state", %{state: state} = context do
      start_session_server(context, "push \"data\"")
      stub Protocol, :format, fn _, _ -> {:ok, "data", :updated_state} end
      stub Transport, :push, fn _, _ -> :ok end

      assert {:noreply, %{protocol_state: :updated_state}} =
        ClientServer.handle_info(:make_request, state)
    end

    test "when request not found unmodified state", %{state: state} = context do
      start_session_server(context, "push \"data\"")
      state = %{state | request: 1_000}

      assert ClientServer.handle_info(:make_request, state) ==
        {:noreply, state}
    end

    test "performs received request", %{state: state} = context do
      start_session_server(context, "push \"data\"")
      expect Protocol, :format, fn {:push, "data"}, _ -> {:ok, "data", %{}} end
      expect Transport, :push, fn _, "data" -> :ok end

      ClientServer.handle_info(:make_request, state)

      verify!()
    end

    test "makes next request", %{state: state} = context do
      start_session_server(context, "push \"data\"")
      stub Protocol, :format, fn _, _ -> {:ok, "data", %{}} end
      stub Transport, :push, fn _, _ -> :ok end

      ClientServer.handle_info(:make_request, state)

      assert_receive :make_request
    end

    test "does not make request on {:think, time}", %{state: state} = context do
      start_session_server(context, "think 10")
      stub Protocol, :format, fn _, _ -> send(self(), :protocol_called) end
      stub Transport, :push, fn _, _ -> send(self(), :tranport_called) end

      ClientServer.handle_info(:make_request, state)

      refute_receive _
    end

    test "waits before next request on {:think, time}", %{state: state} = context do
      start_session_server(context, "think 0")

      ClientServer.handle_info(:make_request, state)

      refute_received :make_request
      assert_receive :make_request
    end

    test "does not make request when there aren't any", %{state: state} = context do
      start_session_server(context, "think 10")
      stub Protocol, :format, fn _, _ -> send(self(), :protocol_called) end
      stub Transport, :push, fn _, _ -> send(self(), :tranport_called) end

      ClientServer.handle_info(:make_request, %{state | request: 1_000})

      refute_receive _
    end

    test "does not make request when not connected", %{state: state} do
      state = %{state | transport: :not_connected}

      ClientServer.handle_info(:make_request, state)

      refute_receive _
    end
  end

  defp default_structs(_) do
    session = %Session{
      id: make_ref(),
      scenario: "push \"data\""
    }
    simulation = %Simulation{
      id: make_ref(),
      sessions: [session],
      url: "localhost",
      transport_mod: Transport,
      protocol_mod: Protocol,
    }
    state = %State{
      id: :id,
      session_id: session.id,
      simulation_id: simulation.id,
      url: "localhost",
      transport_mod: Transport,
      protocol_mod: Protocol,
      protocol_state: %{},
    }

    {:ok, session: session, simulation: simulation, state: state}
  end

  defp start_config_server(%{simulation: simulation}) do
    {:ok, _} = start_supervised({Fury.Simulation.ConfigServer, simulation})

    :ok
  end

  defp start_session_server(context, scenario) do
    context = update_session_scenario(context, scenario)
    start_config_server(context)
    %{simulation: %{id: simulation_id}, session: %{id: session_id}} = context
    opts = [start: {SessionServer, :start_link, [simulation_id, session_id]}]
    {:ok, _} = start_supervised(SessionServer, opts)

    :ok
  end

  defp update_session_scenario(context, scenario) do
    %{simulation: simulation, session: session} = context
    session = %{session | scenario: scenario}
    simulation = %{simulation | sessions: [session]}
    %{context | simulation: simulation}
  end
end
