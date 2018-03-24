defmodule Fury.Session do
  alias Fury.SessionServer
  alias Fury.SessionSupervisor
  alias Fury.Session.Cache

  def new(%Db.Session{} = session, %Db.Simulation{} = simulation) do
    SessionSupervisor.start_child(session, simulation)
  end

  def start_clients(id, ids) do
    GenServer.call(SessionServer.name(id), {:start_clients, ids})
  end

  def get_request(id, request_id) do
    case Cache.get(id, request_id) do
      :error ->
        GenServer.call(SessionServer.name(id), {:get_request, request_id})

      request ->
        request
    end
  end
end
