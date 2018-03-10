defmodule Fury.ClientServerTest do
  use ExUnit.Case, async: true

  import Mox

  alias Fury.ClientServer
  alias Fury.ClientServer.State
  alias Fury.Mock.{Protocol, Storm, Transport}

  setup :set_mox_global
  setup do
    stub Protocol, :init, fn -> %{} end
    stub Transport, :connect, fn _, _ -> {:ok, self()} end

    start_opts = [Transport, Protocol, :session_id]
    state = %State{
      transport_mod: Transport,
      protocol_mod: Protocol,
      session_id: :session_id,
      session: %{}
    }

    {:ok, start_opts: start_opts, state: state}
  end

  describe "start_link/2" do
    test "starts new ClientServer", %{start_opts: opts} do
      assert {:ok, pid} = ClientServer.start_link([], opts)

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
    end

    test "starts making requests when transport connects", %{state: state} do
      stub Transport, :connect, fn _, _->
        {:ok, self()}
      end

      ClientServer.handle_info(:connect, state)

      assert_receive {:make_request, 0}
    end

    test "on error sets transport to :not_connected", %{state: state} do
      pid = self()
      expect Transport, :connect, fn "localhost", [client: ^pid] ->
        {:error, :timeout}
      end

      assert ClientServer.handle_info(:connect, state) ==
        {:noreply, %{state | transport: :not_connected}}
    end

    test "does not make requests on transport error", %{state: state} do
      stub Transport, :connect, fn _, _->
        {:error, :timeout}
      end

      ClientServer.handle_info(:connect, state)

      refute_receive {:make_request, 0}
    end
  end

  describe "handle_info({:transport_data, data}, state)" do
    test "invokes protocol to handle data", %{state: state} do
      expect Protocol, :handle_data, fn "data", %{} ->
        {:ok, :updated_session}
      end

      assert ClientServer.handle_info({:transport_data, "data"}, state) ==
        {:noreply, %{state | session: :updated_session}}
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
      # stub Protocol, :format, fn _, _ -> %{} end
      # stub Transport, :push, fn _, _ -> :ok end
      # stub Storm, :get_request, fn _, _ -> {:error, :not_found} end

      {:ok, state: %{state | transport: self()}}
    end

    test "returns unmodified state", %{state: state} do
      stub Storm, :get_request, fn _, _ -> {:error, :not_found} end

      assert ClientServer.handle_info({:make_request, 0}, state) ==
        {:noreply, state}
    end

    test "invokes StormBridge to get request", %{state: state} do
      expect Storm, :get_request, fn _, _ -> {:error, :not_found} end

      ClientServer.handle_info({:make_request, 0}, state)

      verify!()
    end


    test "performs received request", %{state: state} do
      stub Storm, :get_request, fn _, _ -> {:ok, {:push, "data"}} end
      expect Protocol, :format, fn {:push, "data"}, _ -> {:ok, "data"} end
      expect Transport, :push, fn _, "data" -> :ok end

      ClientServer.handle_info({:make_request, 0}, state)

      verify!()
    end

    test "makes next request", %{state: state} do
      stub Storm, :get_request, fn _, _ -> {:ok, {:push, "data"}} end
      stub Protocol, :format, fn _, _ -> {:ok, "data"} end
      stub Transport, :push, fn _, _ -> :ok end

      ClientServer.handle_info({:make_request, 0}, state)

      assert_receive {:make_request, 1}
    end

    test "does not make request on {:think, time}", %{state: state} do
      pid = self()
      stub Storm, :get_request, fn _, _ -> {:ok, {:think, 1}} end
      stub Protocol, :format, fn _, _ -> send(pid, :protocol_called) end
      stub Transport, :push, fn _, _ -> send(pid, :tranport_called) end

      ClientServer.handle_info({:make_request, 0}, state)

      refute_receive _
    end

    test "waits before next request on {:think, time}", %{state: state} do
      stub Storm, :get_request, fn _, _ -> {:ok, {:think, 0}} end

      ClientServer.handle_info({:make_request, 0}, state)

      refute_received {:make_request, 1}
      assert_receive {:make_request, 1}
    end

    test "does not make request when there aren't any", %{state: state} do
      pid = self()
      stub Storm, :get_request, fn _, _ -> {:error, :not_found} end
      stub Protocol, :format, fn _, _ -> send(pid, :protocol_called) end
      stub Transport, :push, fn _, _ -> send(pid, :tranport_called) end

      ClientServer.handle_info({:make_request, 0}, state)

      refute_receive _
    end

    test "does not make request when not connected", %{state: state} do
      stub Storm, :get_request, fn _, _ -> send(self(), :bridge_called) end
      state = %{state | transport: :not_connected}

      ClientServer.handle_info({:make_request, 0}, state)

      refute_receive _
    end
  end
end
