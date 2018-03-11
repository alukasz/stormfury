defmodule Fury.SessionSupervisor do
  alias Fury.SessionServer

  def start_link(_) do
    DynamicSupervisor.start_link(strategy: :one_for_one, name: __MODULE__)
  end

  def start_child(id, url, transport_mod, protocol_mod) do
    child_spec = {SessionServer, [id, url, transport_mod, protocol_mod]}

    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end
end
