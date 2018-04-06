defmodule Fury.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      Fury.RegistrySupervisor,
      Fury.ClientSupervisor
    ]
    opts = [
      strategy: :one_for_one,
      name: Fury.Supervisor
    ]

    Supervisor.start_link(children, opts)
  end
end
