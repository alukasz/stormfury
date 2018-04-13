defmodule Fury.Session.SessionsSupervisor do
  use DynamicSupervisor

  alias Fury.Session.SessionSupervisor

  def start_link(sessions) do
    DynamicSupervisor.start_link(__MODULE__, sessions)
  end

  def init(sessions) do
    start_sessions(self(), sessions)

    DynamicSupervisor.init(strategy: :one_for_one)
  end

  defp start_sessions(supervisor, sessions) do
    spawn fn ->
      Enum.each(sessions, &start_session(supervisor, &1))
    end
  end

  defp start_session(supervisor, session) do
    child_spec = launcher_spec(session)

    {:ok, _} = GenServer.call(supervisor, {:start_child, child_spec})
  end

  defp launcher_spec(session) do
    {
      {SessionSupervisor, :start_link, [session]},
      :permanent,
      500,
      :supervisor,
      :dynamic
    }
  end
end
