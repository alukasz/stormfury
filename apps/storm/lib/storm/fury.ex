defmodule Storm.Fury do
  @behaviour Storm.FuryBridge

  @timeout :timer.seconds(5)

  @impl true
  def start_simulation(id, sessions) do
    request = {:start_simulation, id, sessions}

    GenServer.multi_call(Node.list(:known), Fury.Server, request, @timeout)
  end

  @impl true
  def start_clients(pid, session_id, ids) do
    GenServer.cast(pid, {:start_clients, session_id, ids})
  end
end
