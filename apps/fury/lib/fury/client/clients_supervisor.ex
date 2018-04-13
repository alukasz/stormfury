defmodule Fury.Client.ClientsSupervisor do
  use DynamicSupervisor, restart: :temporary

  alias Fury.Client
  alias Fury.Client.ClientSupervisor

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, [])
  end

  def start_child(pid, %Client{} = state) do
    child_spec = {ClientSupervisor, state}

    DynamicSupervisor.start_child(pid, child_spec)
  end

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
