defmodule Fury.Transport.WebSocketTest do
  use Fury.TestServerCase, async: true

  alias Fury.Transport.WebSocket

  test "connect/2 connects to server", %{ws_url: url, port: port} do
    assert {:ok, _} = WebSocket.connect(url, client: self())

    assert_receive {:web_socket_server, ^port, :connected}
  end

  test "connect/2 returns error tuple on timeout" do
    assert {:error, :timeout} =
      WebSocket.connect("ws://localhost", client: self(), timeout: 10)
  end

  test "connect/2 returns error tuple on invalid url" do
    assert {:error, _} = WebSocket.connect("invalid", client: self())
  end

  test "push/2 pushes message to server", %{ws_url: url, port: port} do
    {:ok, transport} = connect(url)

    assert :ok = WebSocket.push(transport, "data")

    assert_receive {:web_socket_server, ^port, {:data, "data"}}
  end

  test "close/1 closes connection", %{ws_url: url, port: port} do
    {:ok, transport} = connect(url)

    assert :ok = WebSocket.close(transport)

    assert_receive {:web_socket_server, ^port, {:terminated, :remote}}
  end

  defp connect(url) do
    {:ok, _} = WebSocket.connect(url, client: self())
  end
end
