defmodule Fury.Transport.WebSocketServer do
  @behaviour :websocket_client

  @keepalive :timer.seconds(30)

  def start_link(opts) do
    url = Keyword.fetch!(opts, :url)
    client = Keyword.fetch!(opts, :client)

    url
    |> to_charlist()
    |> :websocket_client.start_link(__MODULE__, %{client: client})
  end

  def init(state) do
    {:once, state}
  end

  def onconnect(_, %{client: client} = state) do
    send(client, :transport_connected)

    {:ok, state, @keepalive}
  end

  def ondisconnect(_, state) do
    {:close, :normal, state}
  end

  def websocket_handle({type, data}, _, %{client: client} = state)
      when type in [:text, :binary] do
    send(client, {:transport_data, data})

    {:ok, state}
  end
  def websocket_handle(_, _, state), do: {:ok, state}

  def websocket_info({:push, data}, _, state) do
    {:reply, {:text, data}, state}
  end
  def websocket_info(:close, _, state), do: {:close, "", state}
  def websocket_info(_, _, state), do: {:ok, state}

  def websocket_terminate(_, _, _), do: :ok
end
