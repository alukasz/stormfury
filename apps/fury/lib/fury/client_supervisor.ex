defmodule Fury.ClientSupervisor do
  use DynamicSupervisor

  alias Fury.ClientServer

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def start_child(id, session_id, url, transport_mod, protocol_mod) do
    client_opts = [id, session_id, url, transport_mod, protocol_mod]
    child_spec = {ClientServer, client_opts}

    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
