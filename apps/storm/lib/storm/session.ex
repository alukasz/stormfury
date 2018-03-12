defmodule Storm.Session do
  alias Storm.Session
  alias Storm.SessionServer
  alias Storm.SessionSupervisor

  defstruct [:id, :clients, :arrival_rate, :scenario]

  def new(simulation_id, %Session{} = session) do
    SessionSupervisor.start_child(simulation_id, session)
  end

  defdelegate get_request(id, index), to: SessionServer
end
