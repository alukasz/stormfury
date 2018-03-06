defmodule Fury.ClientServerTest do
  use ExUnit.Case, async: true

  import Mox

  alias Fury.ClientServer
  alias Fury.ClientServer.State
  alias Fury.Mock.{Protocol, Transport}

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

    test "on error sets transport to :not_connected", %{state: state} do
      pid = self()
      expect Transport, :connect, fn "localhost", [client: ^pid] ->
        {:error, :timeout}
      end

      assert ClientServer.handle_info(:connect, state) ==
        {:noreply, %{state | transport: :not_connected}}
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
end
