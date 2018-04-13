defmodule Fury.Transport.WebSocket do
  use Fury.Transport

  alias Fury.Transport.WebSocketServer

  @impl true
  def connect(opts) do
    WebSocketServer.start_link(opts)
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
