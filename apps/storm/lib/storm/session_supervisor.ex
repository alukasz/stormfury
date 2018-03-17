defmodule Storm.SessionSupervisor do
  use DynamicSupervisor

  alias Storm.Simulation
  alias Storm.SessionServer

  @registry Storm.SessionSupervisor.Registry

  def start_link(%Simulation{id: id}) do
    DynamicSupervisor.start_link(__MODULE__, [], name: name(id))
  end

  def start_child(%{simulation_id: simulation_id} = session) do
    child_spec = {SessionServer, session}

    {:ok, _} = DynamicSupervisor.start_child(name(simulation_id), child_spec)
  end

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  defp name(id) do
    {:via, Registry, {@registry, id}}
  end
end
