defmodule Fury.ClientSupervisor do
  alias Fury.ClientServer

  def start_link(_) do
    DynamicSupervisor.start_link(strategy: :one_for_one, name: __MODULE__)
  end

  def start_child(transport_mod, protocol_mod, session_id) do
    child_spec = {ClientServer, [transport_mod, protocol_mod, session_id]}

    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end
end
