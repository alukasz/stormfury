defmodule Fury.Transport.WebSocketServerTest do
  use ExUnit.Case, async: true

  alias Fury.Transport.WebSocketServer

  setup do
    state = %{client: self()}

    {:ok, state: state}
  end

  describe "onconnect/2" do
    test "specifies keep alive ping interval", %{state: state} do
      assert {:ok, ^state, 30_000} = WebSocketServer.onconnect(:req, state)
    end

    test "sends message", %{state: state} do
      WebSocketServer.onconnect(:req, state)

      assert_received :transport_connected
    end
  end

  describe "ondisconnect/2" do
    test "sends message to client", %{state: state} do
      WebSocketServer.ondisconnect(:reason, state)

      assert_received {:transport_disconnected, :reason}
    end
  end

  describe "websocket_handle/3" do
    test "sends text frame to client", %{state: state} do
      WebSocketServer.websocket_handle({:text, "data"}, :conn, state)

      assert_receive {:transport_data, "data"}
    end

    test "sends binary frame to client", %{state: state} do
      WebSocketServer.websocket_handle({:binary, "data"}, :conn, state)

      assert_receive {:transport_data, "data"}
    end
  end

  describe "websocket_info/3" do
    test "encodes and pushes data", %{state: state} do

      assert WebSocketServer.websocket_info({:push, "data"}, :conn, state) ==
        {:reply, {:text, "data"}, state}
    end

    test "closes connection", %{state: state} do
      assert WebSocketServer.websocket_info(:close, :conn, state) ==
        {:close, "", state}
    end
  end
end
