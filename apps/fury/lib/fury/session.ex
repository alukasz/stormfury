defmodule Fury.Session do
  alias Fury.Session.SessionServer
  alias Fury.Session.SessionSupervisor

  defstruct [
    :id
  ]

  def start(simulation_id, session_id) do
    SessionSupervisor.start_child(supervisor_name(simulation_id), session_id)
  end

  def name(id) do
    {:via, Registry, {Fury.Registry.Session, id}}
  end

  def supervisor_name(id) do
    {:via, Registry, {Fury.Registry.SessionSupervisor, id}}
  end
end
