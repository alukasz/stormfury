defmodule Fury.RegistrySupervisor do
  use Supervisor

  alias Fury.Session

  def start_link(_) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    children = [
      {Registry, name: Fury.Registry.Simulation, keys: :unique},
      {Registry, name: Fury.Registry.Config, keys: :unique},
      {Registry, name: Fury.Registry.SessionSupervisor, keys: :unique},
      {Registry, name: Fury.Registry.Session, keys: :unique},
      {Registry, name: Fury.Registry.ClientSupervisor, keys: :unique},
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
