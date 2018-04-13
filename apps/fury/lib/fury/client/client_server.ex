defmodule Fury.Client.ClientServer do
  use GenServer

  alias Fury.Client
  alias Fury.Session
  alias Fury.Simulation.Config
  alias Storm.DSL.Util

  def start_link(%Client{} = state) do
    GenServer.start_link(__MODULE__, state)
  end

  def init(state) do
    connect()

    {:ok, state}
  end

  def handle_info(:connect, state) do
    %{transport_mod: transport_mod, url: url} = state

    case Client.connect(transport_mod, url) do
      {:ok, transport} ->
        schedule_request()
        {:noreply, %{state | transport: transport}}

      {:error, _} ->
        {:noreply, %{state | transport: :not_connected}}
    end
  end
  def handle_info({:transport_data, data}, state) do
    %{protocol_mod: protocol_mod, protocol_state: protocol_state} = state

    {:ok, protocol_state} = protocol_mod.handle_data(data, protocol_state)

    {:noreply, %{state | protocol_state: protocol_state}}
  end
  def handle_info({:transport_disconnected, _reason}, state) do
    {:noreply, %{state | transport: :not_connected}}
  end
  def handle_info(:make_request, %{transport: :not_connected} = state) do
    {:noreply, state}
  end
  def handle_info(:make_request, state) do
    %{request: request_id, session_id: session_id} = state

    case Session.get_request(session_id, request_id) do
      :error ->
        {:noreply, state}

      :done ->
        {:noreply, state}

      {:think, time} ->
        schedule_request_after(:timer.seconds(time))
        {:noreply, %{state | request: request_id + 1}}

      request ->
        protocol_state = do_make_request(request, state)
        schedule_request()
        {:noreply, %{state | protocol_state: protocol_state,
                             request: request_id + 1}}
    end
  end

  defp do_make_request(request, state) do
    %{id: id, transport_mod: transport_mod, transport: transport,
      protocol_mod: protocol_mod, protocol_state: protocol_state} = state

    request = put_client_id(request, id)
    Client.make_request(transport_mod, transport, protocol_mod,
                        protocol_state, request)
  end

  defp put_client_id({_, payload} = request, id) do
    payload = Util.replace_vars(payload, %{"id" => id})
    put_elem(request, 1, payload)
  end

  defp connect do
    send(self(), :connect)
  end

  defp schedule_request do
    send(self(), :make_request)
  end
  defp schedule_request_after(time) do
    Process.send_after(self(), :make_request, time)
  end
end
