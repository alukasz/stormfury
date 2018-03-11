defmodule Fury.Session do
  alias Fury.SessionServer
  alias Fury.SessionSupervisor

  def new(id, name) do
    SessionSupervisor.start_child(id, name)
  end

  defdelegate get_url(session_id), to: SessionServer

  defdelegate get_request(session_id, request_id), to: SessionServer
end
