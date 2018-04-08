defmodule Storm.Launcher.LauncherSupervisor do
  use DynamicSupervisor

  alias Storm.Launcher.LauncherServer

  def start_link([simulation_id, sessions]) do
    {:ok, sup} = DynamicSupervisor.start_link(__MODULE__, simulation_id)
    start_launchers(sup, sessions)

    {:ok, sup}
  end

  def start_child(supervisor, session_id) do
    {:ok, pid} =
      DynamicSupervisor.start_child(supervisor, launcher_spec(session_id))

    {:ok, pid}
  end

  def init(simulation_id) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  defp start_launchers(pid, sessions) do
    Enum.each(sessions, &start_child(pid, &1.id))
  end

  defp launcher_spec(session_id) do
    {LauncherServer, session_id}
  end
end
