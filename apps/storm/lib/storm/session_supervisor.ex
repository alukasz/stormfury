defmodule Storm.SessionSupervisor do
  use DynamicSupervisor

  alias Storm.Session
  alias Storm.SessionServer

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def start_child(session) do
    child_spec = {SessionServer, session}

    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
