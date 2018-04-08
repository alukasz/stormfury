defmodule Fury.Session do
  defstruct [
    :id,
    :scenario,
    :simulation_id,
    requests: []
  ]

  def get_request(session_id, id) do
    GenServer.call(name(session_id), {:get_request, id})
  end

  def start_clients(session_id, client_ids) do
    GenServer.call(name(session_id), {:start_clients, client_ids})
  end

  def name(session_id) do
    {:via, Registry, {Fury.Registry.Session, session_id}}
  end
end
