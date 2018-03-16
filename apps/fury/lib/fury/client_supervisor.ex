defmodule Fury.ClientSupervisor do
  use DynamicSupervisor

  alias Fury.ClientServer

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def start_child(id, url, transport_mod, protocol_mod, session_id) do
    child_spec = {ClientServer, [id, url, transport_mod,
                                 protocol_mod, session_id]}

    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
