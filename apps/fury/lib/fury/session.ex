defmodule Fury.Session do
  alias Fury.SessionServer

  def new(id, name) do
    SessionServer.start_link([id, name])
  end

  defdelegate get_url(session_id), to: SessionServer

  defdelegate get_request(session_id, request_id), to: SessionServer
end
