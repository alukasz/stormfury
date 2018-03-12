defmodule Storm.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {Registry, name: Storm.Simulation.Registry, keys: :unique},
      {Registry, name: Storm.Session.Registry, keys: :unique},
      Storm.SimulationsSupervisor
    ]
    opts = [
      strategy: :one_for_one,
      name: Storm.Supervisor
    ]

    Supervisor.start_link(children, opts)
  end
end
