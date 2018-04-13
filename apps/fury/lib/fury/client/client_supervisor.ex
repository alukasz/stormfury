defmodule Fury.Client.ClientSupervisor do
  use DynamicSupervisor

  alias Fury.Client
  alias Fury.Client.ClientServer

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, [])
  end

  def start_child(supervisor, state) do
    child_spec = client_spec(state)

    DynamicSupervisor.start_child(supervisor, child_spec)
  end

  def init(_) do
    DynamicSupervisor.init( strategy: :one_for_one)
  end

  defp name(simulation_id) do
    Client.supervisor_name(simulation_id)
  end

  defp client_spec(state) do
    {ClientServer, state}
  end
end
