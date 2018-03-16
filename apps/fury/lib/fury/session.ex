defmodule Fury.Session do
  alias Fury.SessionServer
  alias Fury.SessionSupervisor

  def new(id, url, transport_mod, protocol_mod) do
    SessionSupervisor.start_child(id, url, transport_mod, protocol_mod)
  end

  def start_clients(id, ids) do
    GenServer.call(SessionServer.name(id), {:start_clients, ids})
  end

  def get_request(id, request_id) do
    GenServer.call(SessionServer.name(id), {:get_request, request_id})
  end
end
