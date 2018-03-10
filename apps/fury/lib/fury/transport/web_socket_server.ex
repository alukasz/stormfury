defmodule Fury.Transport.WebSocketServer do
  @behaviour :websocket_client

  @keepalive :timer.seconds(30)
  @connection_timeout :timer.seconds(5)

  def start_link(url, opts) do
    timeout = Keyword.get(opts, :timeout, @connection_timeout)
    client = Keyword.fetch!(opts, :client)

    url
    |> to_charlist()
    |> :websocket_client.start_link(__MODULE__, %{client: client})
    |> wait_for_connection(timeout)
  end

  def init(state) do
    {:once, state}
  end

  def onconnect(_, %{client: client} = state) do
    send(client, :transport_connected)

    {:ok, state, @keepalive}
  end

  def ondisconnect(reason,  %{client: client} = state) do
    send(client, {:transport_disconnected, reason})

    {:ok, state}
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

  defp wait_for_connection({:ok, transport}, timeout) do
    receive do
      :transport_connected -> {:ok, transport}
    after
      timeout -> {:error, :timeout}
    end
  end
  defp wait_for_connection(error, _), do: error
end
