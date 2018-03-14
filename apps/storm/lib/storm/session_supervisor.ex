defmodule Storm.SessionSupervisor do
  use DynamicSupervisor

  alias Storm.SessionServer

  @registry Storm.SessionSupervisor.Registry

  def start_link(simulation_id) do
    DynamicSupervisor.start_link(__MODULE__, [], name: name(simulation_id))
  end

  def start_child(%{simulation_id: simulation_id} = session) do
    child_spec = {SessionServer, session}

    DynamicSupervisor.start_child(name(simulation_id), child_spec)
  end

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  defp name(id) do
    {:via, Registry, {@registry, id}}
  end
end
