defmodule Fury.SessionServer do
  use GenServer

  alias Fury.ClientSupervisor
  alias Fury.Session.Cache

  @registry Fury.Session.Registry
  @storm_bridge Application.get_env(:fury, :storm_bridge)

  defmodule State do
    defstruct [:id, :url, :transport_mod, :protocol_mod]
  end

  def start_link([id | _] = opts) do
    GenServer.start_link(__MODULE__, opts, name: name(id))
  end

  def name(id) do
    {:via, Registry, {@registry, id}}
  end

  def init([id, url, transport_mod, protocol_mod]) do
    state = %State{
      id: id,
      url: url,
      transport_mod: transport_mod,
      protocol_mod: protocol_mod
    }
    Cache.new(id)

    {:ok, state}
  end

  def handle_call({:get_request, request_id}, _, %{id: id} = state) do
    case @storm_bridge.get_request(id, request_id) do
      {:ok, request} ->
        Cache.put(id, request_id, request)
        {:reply, {:ok, request}, state}

      {:error, :not_found} = request ->
        Cache.put(id, request_id, :not_found)
        {:reply, {:ok, :not_found}, state}

      error ->
        {:reply, error, state}
    end
  end
  def handle_call({:start_clients, ids}, _, state) do
    %{transport_mod: transport_mod, protocol_mod: protocol_mod,
      id: id, url: url} = state

    Enum.each ids, fn client_id ->
      {:ok, _} = ClientSupervisor.start_child(client_id, url, transport_mod,
                                              protocol_mod, id)
    end

    {:reply, :ok, state}
  end
end