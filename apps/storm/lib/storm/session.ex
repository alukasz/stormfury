defmodule Storm.Session do
  alias Storm.Session
  alias Storm.SessionServer
  alias Storm.SessionSupervisor

  defstruct [:id, :simulation_id, :clients, :arrival_rate, :scenario]

  def new(%Session{} = session) do
    SessionSupervisor.start_child(session)
  end

  def get_request(session, index) do
    GenServer.call(SessionServer.name(session), {:get_request, index})
  end
end
