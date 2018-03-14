defmodule Fury.Session do
  alias Fury.SessionServer
  alias Fury.SessionSupervisor

  def new(id, url, transport_mod, protocol_mod) do
    SessionSupervisor.start_child(id, url, transport_mod, protocol_mod)
  end

  def get_url(id) do
    GenServer.call(SessionServer.name(id), :get_url)
  end

  def get_request(id, request_id) do
    GenServer.call(SessionServer.name(id), {:get_request, request_id})
  end
end
