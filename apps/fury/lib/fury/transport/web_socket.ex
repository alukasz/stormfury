defmodule Fury.Transport.WebSocket do
  @behaviour Fury.Transport

  alias Fury.Transport.WebSocketServer

  @impl true
  def connect(url, opts \\ []) when is_binary(url) do
    WebSocketServer.start_link(url, opts)
  end

  @impl true
  def push(transport, data) do
    send(transport, {:push, data})

    :ok
  end

  @impl true
  def close(transport) do
    send(transport, :close)

    :ok
  end
end
