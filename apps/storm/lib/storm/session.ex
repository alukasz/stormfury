defmodule Storm.Session do
  alias Storm.SessionServer
  alias Storm.SessionSupervisor

  def new(%Db.Session{} = session) do
    SessionSupervisor.start_child(session)
  end

  def get_request(session, index) do
    GenServer.call(SessionServer.name(session), {:get_request, index})
  end
end
