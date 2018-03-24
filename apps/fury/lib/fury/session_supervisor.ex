defmodule Fury.SessionSupervisor do
  use DynamicSupervisor

  alias Fury.SessionServer

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def start_child(%Db.Session{} = session, %Db.Simulation{} = simulation) do
    child_spec = {SessionServer, [session, simulation]}

    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
