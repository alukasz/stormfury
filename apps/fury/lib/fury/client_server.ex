defmodule Fury.ClientServer do
  use GenServer

  alias Fury.Client
  alias Fury.Session

  defmodule State do
    defstruct [:transport_mod, :protocol_mod, :session_id, :session,
               transport: :not_connected]
  end

  def start_link([], opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init([transport_mod, protocol_mod, session_id]) do
    state = %State{
      transport_mod: transport_mod,
      protocol_mod: protocol_mod,
      session_id: session_id,
      session: protocol_mod.init()
    }
    connect()

    {:ok, state}
  end

  def handle_info(:connect, state) do
    %{transport_mod: transport_mod, session_id: session_id} = state
    {:ok, url} = Session.get_url(session_id)

    case Client.connect(transport_mod, url) do
      {:ok, transport} ->
        {:noreply, %{state | transport: transport}}

      {:error, _} ->
        {:noreply, %{state | transport: :not_connected}}
    end
  end
  def handle_info({:transport_data, data}, state) do
    %{protocol_mod: protocol_mod, session: session} = state

    {:ok, session} = protocol_mod.handle_data(data, session)

    {:noreply, %{state | session: session}}
  end
  def handle_info(:transport_disconnected, state) do
    {:noreply, %{state | transport: :not_connected}}
  end

  defp connect do
    send(self(), :connect)
  end
end
