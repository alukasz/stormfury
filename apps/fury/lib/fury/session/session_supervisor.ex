defmodule Fury.Session.SessionSupervisor do
  use DynamicSupervisor

  alias Fury.Session
  alias Fury.Session.SessionServer

  def start_link(simulation_id) do
    DynamicSupervisor.start_link(
      __MODULE__,
      simulation_id,
      name: name(simulation_id)
    )
  end

  def start_child(supervisor, session_id) do
    DynamicSupervisor.start_child(supervisor, session_spec(session_id))
  end

  def init(simulation_id) do
    DynamicSupervisor.init(
      strategy: :one_for_one,
      extra_arguments: [simulation_id]
    )
  end

  defp name(simulation_id) do
    Session.supervisor_name(simulation_id)
  end

  defp session_spec(session_id) do
    {SessionServer, session_id}
  end
end
