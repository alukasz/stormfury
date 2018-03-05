defmodule Fury.TestServer.WebSocketHandler do
  def init(req, state) do
    {:cowboy_websocket, req, state}
  end

  def websocket_init(%{test: test, port: port} = state) do
    send(test, {:web_socket_server, port, :connected})

    {:ok, state}
  end

  def websocket_handle({type, data}, %{test: test, port: port} = state)
  when type in [:text, :binary] do
    send(test, {:web_socket_server, port, {:data, data}})

    {:ok, state}
  end

  def websocket_info(message, %{test: test, port: port} = state) do
    send(test, {:web_socket_server, port, {:message, message}})

    {:ok, state}
  end

  def terminate(reason, _, %{test: test, port: port} = state) do
    send(test, {:web_socket_server, port, {:terminated, reason}})

    :ok
  end
end
