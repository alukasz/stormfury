defmodule Fury.Session do
  alias Fury.SessionServer
  alias Fury.SessionSupervisor

  def new(id, url, transport_mod, protocol_mod) do
    SessionSupervisor.start_child(id, url, transport_mod, protocol_mod)
  end

  defdelegate get_url(session_id), to: SessionServer

  defdelegate get_request(session_id, request_id), to: SessionServer
end
