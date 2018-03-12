defmodule Storm.Session do
  alias Storm.Session
  alias Storm.SessionServer

  defstruct [:id, :clients, :arrival_rate, :scenario]

  def new(%Storm.Session{} = session) do
    SessionServer.start_link(session)
  end

  defdelegate get_request(id, index), to: SessionServer
end
