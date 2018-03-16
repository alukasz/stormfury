defmodule Fury.ClientServer do
  use GenServer

  alias Fury.Client
  alias Fury.Session
  alias Storm.DSL.Util

  defmodule State do
    defstruct [:id, :url, :transport_mod, :protocol_mod, :session_id, :session,
               request_id: 0, transport: :not_connected]
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init([id, url, transport_mod, protocol_mod, session_id]) do
    state = %State{
      id: id,
      url: url,
      transport_mod: transport_mod,
      protocol_mod: protocol_mod,
      session_id: session_id,
      session: protocol_mod.init()
    }
    connect()

    {:ok, state}
  end

  def handle_info(:connect, state) do
    %{transport_mod: transport_mod, url: url} = state

    case Client.connect(transport_mod, url) do
      {:ok, transport} ->
        make_request()
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
  def handle_info(:make_request, %{transport: :not_connected} = state) do
    {:noreply, state}
  end
  def handle_info(:make_request, state) do
    %{transport_mod: transport_mod, transport: transport,
      protocol_mod: protocol_mod, session_id: session_id,
      request_id: request_id, id: id} = state

    case Session.get_request(session_id, request_id) do
      {:ok, {:think, time}} ->
        make_request_after(:timer.seconds(time))
        {:noreply, %{state | request_id: request_id + 1}}

      {:ok, request} ->
        request = put_client_id(request, id)
        Client.make_request(transport_mod, transport, protocol_mod, request)
        make_request()
        {:noreply, %{state | request_id: request_id + 1}}

      {:error, :not_found} ->
        {:noreply, state}
    end
  end

  defp put_client_id({_, payload} = request, id) do
    payload = Util.replace_vars(payload, %{"id" => id})
    put_elem(request, 1, payload)
  end

  defp connect do
    send(self(), :connect)
  end

  defp make_request do
    send(self(), :make_request)
  end
  defp make_request_after(time) do
    Process.send_after(self(), :make_request, time)
  end
end
