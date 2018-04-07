defmodule Storm.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      Storm.RegistrySupervisor,
      Storm.SimulationsSupervisor
    ]
    opts = [
      strategy: :rest_for_one,
      name: Storm.Supervisor
    ]

    Supervisor.start_link(children, opts)
  end
end
