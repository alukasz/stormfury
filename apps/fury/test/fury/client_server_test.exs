defmodule Fury.ClientServerTest do
  use ExUnit.Case

  import Mox

  alias Fury.ClientServer
  alias Fury.ClientServer.State
  alias Fury.SessionServer
  alias Fury.Mock.{Protocol, Storm, Transport}

  setup :start_session_server
  setup :default_stubs
  setup %{session_id: session_id} do

    start_opts = [:id, session_id, "localhost", Transport, Protocol]
    state = %State{
      id: :id,
      session_id: session_id,
      url: "localhost",
      transport_mod: Transport,
      protocol_mod: Protocol,
      protocol_state: %{},
    }

    {:ok, start_opts: start_opts, state: state}
  end

  describe "start_link/1" do
    setup :set_mox_global

    test "starts new ClientServer", %{start_opts: opts} do
      assert {:ok, pid} = ClientServer.start_link(opts)

      assert is_pid(pid)
    end
  end

  describe "init/1" do
    test "builds state", %{start_opts: opts, state: state} do
      assert ClientServer.init(opts) == {:ok, state}
    end

    test "initializes session", %{start_opts: opts} do
      expect Protocol, :init, fn -> %{} end

      ClientServer.init(opts)

      verify!()
    end

    test "sends message to connect", %{start_opts: opts} do
      ClientServer.init(opts)

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

    test "when request is found increases state.request_id", %{state: state} do
      stub Storm, :get_request, fn _, _ -> {:ok, {:think, 1}} end
      expected_request_id = state.request_id + 1

      assert {:noreply, %{request_id: ^expected_request_id}} =
        ClientServer.handle_info(:make_request, state)
    end

    test "when request is found updates protocol_state", %{state: state} do
      stub Storm, :get_request, fn _, _ -> {:ok, {:push, "data"}} end
      stub Protocol, :format, fn _, _ -> {:ok, "data", :updated_state} end
      stub Transport, :push, fn _, _ -> :ok end

      assert {:noreply, %{protocol_state: :updated_state}} =
        ClientServer.handle_info(:make_request, state)
    end

    test "when request not found unmodified state", %{state: state} do
      stub Storm, :get_request, fn _, _ -> {:error, :not_found} end

      assert ClientServer.handle_info(:make_request, state) ==
        {:noreply, state}
    end

    test "invokes StormBridge to get request", %{state: state} do
      expect Storm, :get_request, fn _, _ -> {:error, :not_found} end

      ClientServer.handle_info(:make_request, state)

      verify!()
    end

    test "performs received request", %{state: state} do
      stub Storm, :get_request, fn _, _ -> {:ok, {:push, "data"}} end
      expect Protocol, :format, fn {:push, "data"}, _ -> {:ok, "data", %{}} end
      expect Transport, :push, fn _, "data" -> :ok end

      ClientServer.handle_info(:make_request, state)

      verify!()
    end

    test "makes next request", %{state: state} do
      stub Storm, :get_request, fn _, _ -> {:ok, {:push, "data"}} end
      stub Protocol, :format, fn _, _ -> {:ok, "data", %{}} end
      stub Transport, :push, fn _, _ -> :ok end

      ClientServer.handle_info(:make_request, state)

      assert_receive :make_request
    end

    test "does not make request on {:think, time}", %{state: state} do
      stub Storm, :get_request, fn _, _ -> {:ok, {:think, 1}} end
      stub Protocol, :format, fn _, _ -> send(self(), :protocol_called) end
      stub Transport, :push, fn _, _ -> send(self(), :tranport_called) end

      ClientServer.handle_info(:make_request, state)

      refute_receive _
    end

    test "waits before next request on {:think, time}", %{state: state} do
      stub Storm, :get_request, fn _, _ -> {:ok, {:think, 0}} end

      ClientServer.handle_info(:make_request, state)

      refute_received :make_request
      assert_receive :make_request
    end

    test "does not make request when there aren't any", %{state: state} do
      pid = self()
      stub Storm, :get_request, fn _, _ -> {:error, :not_found} end
      stub Protocol, :format, fn _, _ -> send(pid, :protocol_called) end
      stub Transport, :push, fn _, _ -> send(pid, :tranport_called) end

      ClientServer.handle_info(:make_request, state)

      refute_receive _
    end

    test "does not make request when not connected", %{state: state} do
      stub Storm, :get_request, fn _, _ -> send(self(), :bridge_called) end
      state = %{state | transport: :not_connected}

      ClientServer.handle_info(:make_request, state)

      refute_receive _
    end
  end

  defp start_session_server(context) do
    session_id = :"client_server_test_#{context.line}"
    simulation = %Db.Simulation{}
    session = %Db.Session{id: session_id}
    {:ok, pid} = start_supervised({SessionServer, [session, simulation]})

    {:ok, session_id: session_id, session_server_pid: pid}
  end

  defp default_stubs(%{session_server_pid: session_server_pid}) do
    allow(Storm, self(), session_server_pid)

    stub Protocol, :init, fn -> %{} end
    stub Transport, :connect, fn _, _ -> {:ok, self()} end
    stub Storm, :get_request, fn _, _ -> {:error, :not_found} end

    :ok
  end
end
