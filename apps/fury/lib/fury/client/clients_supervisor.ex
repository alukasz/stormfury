defmodule Fury.Client.ClientsSupervisor do
  use DynamicSupervisor, restart: :temporary

  alias Fury.Client

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, [])
  end

  def start_child(pid, %Client{} = state) do
    child_spec = client_spec(state)

    DynamicSupervisor.start_child(pid, child_spec)
  end

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  defp client_spec(state) do
    {ClientServer, state}
  end
end
