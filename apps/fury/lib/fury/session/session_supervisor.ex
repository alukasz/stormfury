defmodule Fury.Session.SessionSupervisor do
  use DynamicSupervisor

  alias Fury.Session.SessionServer

  def start_link([simulation_id, sessions]) do
    {:ok, sup} = DynamicSupervisor.start_link(__MODULE__, simulation_id)
    start_sessions(sup, sessions)

    {:ok, sup}
  end

  def start_child(supervisor, session_id) do
    DynamicSupervisor.start_child(supervisor, session_spec(session_id))
  end

  def init(simulation_id) do
    DynamicSupervisor.init(
      strategy: :one_for_one,
      extra_arguments: [simulation_id]
    )
  end

  defp start_sessions(pid, sessions) do
    Enum.each(sessions, &start_child(pid, &1.id))
  end

  defp session_spec(session_id) do
    {SessionServer, session_id}
  end
end
