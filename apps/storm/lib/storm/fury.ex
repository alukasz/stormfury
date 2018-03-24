defmodule Storm.Fury do
  @behaviour Storm.FuryBridge

  @impl true
  def start_sessions(node, simulation_id) do
    :rpc.call(node, Fury, :start_sessions, [simulation_id])
  end

  @impl true
  def start_clients(node, session_id, range) do
    :rpc.call(node, Fury.Session, :start_clients, [session_id, range])
  end
end
