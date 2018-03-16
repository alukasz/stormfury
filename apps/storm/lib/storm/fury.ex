defmodule Storm.Fury do
  @behaviour Storm.FuryBridge

  @impl true
  def start_session(node, session) do
    :rpc.call(node, Fury.Session, :new, [session])
  end

  @impl true
  def start_clients(node, session_id, range) do
    :rpc.call(node, Fury.Session, :start_clients, [session_id, range])
  end
end
