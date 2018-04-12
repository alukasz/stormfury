defmodule Storm.Launcher.LauncherSupervisor do
  use DynamicSupervisor

  alias Storm.Launcher.LauncherServer

  def start_link(opts) do
    DynamicSupervisor.start_link(__MODULE__, opts)
  end

  def init([simulation_id, sessions]) do
    start_launchers(self(), simulation_id, sessions)

    DynamicSupervisor.init(strategy: :one_for_one)
  end

  defp start_launchers(supervisor, simulation_id, sessions) do
    spawn fn ->
      Enum.each(sessions, &start_launcher(supervisor, simulation_id, &1.id))
    end
  end

  defp start_launcher(supervisor, simulation_id, session_id) do
    child_spec = launcher_spec(simulation_id, session_id)

    {:ok, _} = GenServer.call(supervisor, {:start_child, child_spec})
  end

  defp launcher_spec(simulation_id, session_id) do
    {
      {LauncherServer, :start_link, [[simulation_id, session_id]]},
      :permanent,
      500,
      :worker,
      :dynamic
    }
  end
end
