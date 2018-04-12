defmodule Storm.Dispatcher.DispatcherSupervisor do
  use Supervisor

  alias Storm.Dispatcher.DispatcherServer
  alias Storm.Launcher.LauncherSupervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts)
  end

  def init([simulation_id, sessions]) do
    children = [
      {DispatcherServer, simulation_id},
      {LauncherSupervisor, [simulation_id, sessions]}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
