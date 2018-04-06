defmodule Fury.Session do
  alias Fury.Session.SessionSupervisor

  defstruct [
    :id,
  ]

  def start(simulation_id, session_id) do
    SessionSupervisor.start_child(supervisor_name(simulation_id), session_id)
  end

  def get_request(session_id, id) do
    {:ok, :not_found}
  end

  def name(session_id) do
    {:via, Registry, {Fury.Registry.Session, session_id}}
  end

  def supervisor_name(simulation_id) do
    {:via, Registry, {Fury.Registry.SessionSupervisor, simulation_id}}
  end
end
