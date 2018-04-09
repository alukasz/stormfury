defmodule Storm.Application do
  @moduledoc false

  use Application

  @nodes Application.get_env(:storm, :nodes, [])

  def start(_type, _args) do
    children = [
      Storm.RegistrySupervisor,
      {Storm.NodeMonitorSupervisor, @nodes},
      Storm.SimulationsSupervisor
    ]
    opts = [
      strategy: :rest_for_one,
      name: Storm.Supervisor
    ]

    Supervisor.start_link(children, opts)
  end
end
