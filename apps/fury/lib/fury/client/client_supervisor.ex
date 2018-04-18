defmodule Fury.Client.ClientSupervisor do
  use Supervisor, restart: :temporary

  alias Fury.Client.ClientFSM

  def start_link(client) do
    Supervisor.start_link(__MODULE__, client)
  end

  def start_transport(supervisor, transport_mod, opts) do
    child_spec = {transport_mod, opts}

    Supervisor.start_child(supervisor, child_spec)
  end

  def init(client) do
    children = [
      {ClientFSM, %{client | supervisor_pid: self()}}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
