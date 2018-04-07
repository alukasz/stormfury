defmodule Storm.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      erl_boot_server(),
      {Registry, name: Storm.Simulation.Registry, keys: :unique},
      {Registry, name: Storm.LoadBalancer.Registry, keys: :unique},
      Storm.SimulationsSupervisor
    ]
    opts = [
      strategy: :one_for_one,
      name: Storm.Supervisor
    ]

    Supervisor.start_link(children, opts)
  end

  defp erl_boot_server do
    %{
      id: :erl_boot_server,
      start: {:erl_boot_server, :start_link, [[]]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end
end
