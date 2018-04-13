defmodule Storm.Dispatcher.DispatcherSupervisor do
  use Supervisor

  alias Storm.Dispatcher.DispatcherServer
  alias Storm.Launcher.LaunchersSupervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts)
  end

  def init([simulation_id, sessions]) do
    children = [
      {DispatcherServer, simulation_id},
      {LaunchersSupervisor, [simulation_id, sessions]}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
