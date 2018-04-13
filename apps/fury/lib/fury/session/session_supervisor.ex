defmodule Fury.Session.SessionSupervisor do
  use Supervisor

  alias Fury.Client.ClientsSupervisor
  alias Fury.Session.SessionServer

  def start_link(session) do
    Supervisor.start_link(__MODULE__, session)
  end

  def start_clients_supervisor(pid) do
    Supervisor.start_child(pid, ClientsSupervisor)
  end

  def init(session) do
    children = [
      {SessionServer, %{session | supervisor_pid: self()}}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
