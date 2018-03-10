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
  def handle_info({:make_request, id}, %{transport: :not_connected} = state) do
    make_request_after(id, :timer.seconds(5))

    {:noreply, state}
  end
  def handle_info({:make_request, request_id}, state) do
    %{transport_mod: transport_mod, transport: transport,
      protocol_mod: protocol_mod, session_id: session_id} = state

    case Session.get_request(session_id, request_id) do
      {:ok, {:think, time}} ->
        make_request_after(request_id + 1, :timer.seconds(time))
        {:noreply, state}

      {:ok, request} ->
        Client.make_request(transport_mod, transport, protocol_mod, request)
        make_request(request_id + 1)
        {:noreply, state}

      {:error, _} ->
        {:noreply, state}
    end
  end


  defp connect do
    send(self(), :connect)
  end

  defp make_request(id \\ 0) do
    send(self(), {:make_request, id})
  end
  defp make_request_after(id , time) do
    Process.send_after(self(), {:make_request, id}, time)
  end
end
