defmodule Fury.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {Registry, name: Fury.Session.Registry, keys: :unique},
      Fury.ClientSupervisor,
      Fury.SessionSupervisor
    ]
    opts = [
      strategy: :one_for_one,
      name: Fury.Supervisor
    ]

    Supervisor.start_link(children, opts)
  end
end
