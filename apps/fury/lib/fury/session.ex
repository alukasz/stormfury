defmodule Fury.Session do
  alias Fury.Session.SessionSupervisor

  defstruct [
    :id,
    :scenario
  ]

  def get_request(session_id, id) do
    GenServer.call(name(session_id), {:get_request, id})
  end

  def name(session_id) do
    {:via, Registry, {Fury.Registry.Session, session_id}}
  end
end
