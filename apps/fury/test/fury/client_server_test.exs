defmodule Fury.ClientServerTest do
  use ExUnit.Case, async: true

  import Mox

  alias Fury.ClientServer
  alias Fury.ClientServer.State
  alias Fury.SessionServer
  alias Fury.Mock.{Protocol, Storm, Transport}

  setup :set_mox_global
  setup %{line: line} do
    stub Protocol, :init, fn -> %{} end
    stub Transport, :connect, fn _, _ -> {:ok, self()} end

    session_id = :"client_server_test_#{line}"
    start_opts = [:id, "localhost", Transport, Protocol, session_id]
    state = %State{
      id: :id,
      url: "localhost",
      transport_mod: Transport,
      protocol_mod: Protocol,
      session_id: session_id,
      session: %{},
      request_id: 0
    }
    session_opts = [session_id, "localhost", Transport, Protocol]
    {:ok, _} = start_supervised({SessionServer, session_opts})

    {:ok, start_opts: start_opts, state: state}
  end

  describe "start_link/1" do
    test "starts new ClientServer", %{start_opts: opts} do
      assert {:ok, pid} = ClientServer.start_link(opts)

      assert is_pid(pid)
    end
  end

  describe "init/1" do
    test "builds state", %{start_opts: opts, state: state} do
      assert {:ok, ^state} = ClientServer.init(opts)
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
      stub Transport, :connect, fn _, _->
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
      stub Transport, :connect, fn _, _->
        {:error, :timeout}
      end

      ClientServer.handle_info(:connect, state)

      refute_receive :make_request
    end
  end

  describe "handle_info({:transport_data, data}, state)" do
    test "invokes protocol to handle data", %{state: state} do
      expect Protocol, :handle_data, fn "data", %{} ->
        {:ok, :updated_session}
      end

      assert ClientServer.handle_info({:transport_data, "data"}, state) ==
        {:noreply, %{state | session: :updated_session}}

      verify!()
    end
  end

  describe "handle_info(:transport_disconnected, state)" do
    test "sets transport to :not_connected", %{state: state} do
      assert ClientServer.handle_info(:transport_disconnected, state) ==
        {:noreply, %{state | transport: :not_connected}}
    end
  end

  describe "handle_info({:make_request, id} state)" do
    setup %{state: state} do
      {:ok, state: %{state | transport: self()}}
    end

    test "when request is found increases state.request_id", %{state: state} do
      stub Storm, :get_request, fn _, _ -> {:ok, {:think, 1}} end

      assert ClientServer.handle_info(:make_request, state) ==
        {:noreply, %{state | request_id: state.request_id + 1}}
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
      expect Protocol, :format, fn {:push, "data"}, _ -> {:ok, "data"} end
      expect Transport, :push, fn _, "data" -> :ok end

      ClientServer.handle_info(:make_request, state)

      verify!()
    end

    test "makes next request", %{state: state} do
      stub Storm, :get_request, fn _, _ -> {:ok, {:push, "data"}} end
      stub Protocol, :format, fn _, _ -> {:ok, "data"} end
      stub Transport, :push, fn _, _ -> :ok end

      ClientServer.handle_info(:make_request, state)

      assert_receive :make_request
    end

    test "does not make request on {:think, time}", %{state: state} do
      pid = self()
      stub Storm, :get_request, fn _, _ -> {:ok, {:think, 1}} end
      stub Protocol, :format, fn _, _ -> send(pid, :protocol_called) end
      stub Transport, :push, fn _, _ -> send(pid, :tranport_called) end

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
end
