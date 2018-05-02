defmodule Fury.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      Fury.RegistrySupervisor,
      Fury.Simulation.SimulationsSupervisor,
      Fury.Server,
    ]
    opts = [
      strategy: :rest_for_one,
      name: Fury.Supervisor
    ]

    Supervisor.start_link(children, opts)
  end
end
