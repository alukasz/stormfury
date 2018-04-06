defmodule Fury.Client.ClientSupervisor do
  use DynamicSupervisor

  alias Fury.Client
  alias Fury.Client.ClientServer

  def start_link(simulation_id) do
    DynamicSupervisor.start_link(
      __MODULE__,
      simulation_id,
      name: name(simulation_id)
    )
  end

  def start_child(supervisor, session_id, client_id) do
    child_spec = client_spec(session_id, client_id)

    DynamicSupervisor.start_child(supervisor, child_spec)
  end

  def init(simulation_id) do
    DynamicSupervisor.init(
      strategy: :one_for_one,
      extra_arguments: [simulation_id]
    )
  end

  defp name(simulation_id) do
    Client.supervisor_name(simulation_id)
  end

  defp client_spec(session_id, client_id) do
    {ClientServer, [session_id, client_id]}
  end
end
