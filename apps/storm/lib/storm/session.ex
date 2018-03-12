defmodule Storm.Session do
  alias Storm.Session
  alias Storm.SessionServer
  alias Storm.SessionSupervisor

  defstruct [:id, :clients, :arrival_rate, :scenario]

  def new(%Storm.Session{} = session) do
    SessionSupervisor.start_child(session)
  end

  defdelegate get_request(id, index), to: SessionServer
end
