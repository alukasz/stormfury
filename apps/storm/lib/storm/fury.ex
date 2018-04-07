defmodule Storm.Fury do
  @behaviour Storm.FuryBridge

  @timeout :timer.seconds(5)

  @impl true
  def start_simulation(simulation) do
    request = {:start_simulation, simulation}

    GenServer.multi_call(Node.list(:known), Fury.Server, request, @timeout)
  end

  @impl true
  def start_clients(node, session_id, ids) do
    :rpc.call(node, Fury.Session, :start_clients, [session_id, ids])
  end
end
