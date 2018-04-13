defmodule Fury.RegistrySupervisor do
  use Supervisor

  def start_link(_) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    children = [
      {Registry, name: Fury.Registry.State, keys: :unique},
      {Registry, name: Fury.Registry.Session, keys: :unique},
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
