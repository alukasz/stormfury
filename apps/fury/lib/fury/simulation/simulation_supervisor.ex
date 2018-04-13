defmodule Fury.Simulation.SimulationSupervisor do
  use Supervisor

  alias Fury.Session.SessionsSupervisor
  alias Fury.Simulation.SimulationServer
  alias Fury.State.StateServer

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts)
  end

  def init([simulation_id, sessions]) do
    children = [
      {StateServer, simulation_id},
      {SimulationServer, [simulation_id, self()]},
      {SessionsSupervisor, sessions}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
