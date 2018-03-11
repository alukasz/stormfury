defmodule Fury.SessionServer do
  use GenServer

  @registry Fury.Session.Registry
  @storm_bridge Application.get_env(:fury, :storm_bridge)

  defmodule State do
    defstruct [:id, :url]
  end

  def start_link([id | _] = opts) do
    GenServer.start_link(__MODULE__, opts, name: name(id))
  end

  def get_url(id) do
    GenServer.call(name(id), :get_url)
  end

  def get_request(id, request_id) do
    GenServer.call(name(id), {:get_request, request_id})
  end

  def init([id, url]) do
    state = %State{
      id: id,
      url: url
    }

    {:ok, state}
  end

  def handle_call(:get_url, _, %{url: url} = state) do
    {:reply, url, state}
  end

  def handle_call({:get_request, request_id}, _, %{id: id} = state) do
    request = @storm_bridge.get_request(id, request_id)

    {:reply, request, state}
  end

  defp name(id) do
    {:via, Registry, {@registry, id}}
  end
end
