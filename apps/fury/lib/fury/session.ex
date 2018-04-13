defmodule Fury.Session do
  defstruct [
    :id,
    :simulation_id,
    :url,
    :protocol_mod,
    :transport_mod,
    :scenario,
    :supervisor_pid,
    :clients_sup_pid,
    :clients_sup_ref,
    requests: []
  ]

  def get_request(session_id, id) do
    GenServer.call(name(session_id), {:get_request, id})
  end

  def start_clients(session_id, client_ids) do
    GenServer.cast(name(session_id), {:start_clients, client_ids})
  end

  def name(session_id) do
    {:via, Registry, {Fury.Registry.Session, session_id}}
  end
end
