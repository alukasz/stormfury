defmodule Fury.Transport.WebSocketTest do
  use Fury.TestServerCase, async: true

  alias Fury.Transport.WebSocket

  test "connect/2 connects to server", %{ws_url: url, port: port} do
    assert {:ok, _} = WebSocket.connect(url: url, client: self())

    assert_receive {:web_socket_server, ^port, :connected}
  end

  test "connect/2 returns error tuple on invalid url" do
    assert {:error, _} = WebSocket.connect(url: "invalid", client: self())
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

  test "implements child_spec/1" do
    child_spec = %{
      id: WebSocket,
      start: {WebSocket, :connect, [:arg]},
      shutdown: 500,
      type: :worker,
      restart: :temporary
    }

    assert WebSocket.child_spec(:arg) == child_spec
  end

  defp connect(url) do
    {:ok, pid} = WebSocket.connect(url: url, client: self())
    receive do
      :transport_connected -> {:ok, pid}
    after 100 ->
        flunk("WebSocket haven't connected")
    end
  end
end
