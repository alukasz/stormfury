defmodule Fury.Storm do
  @behaviour Fury.StormBridge

  @storm_node Application.get_env(:fury, :storm_node)

  @impl true
  def get_request(session, id) do
    :rpc.call(@storm_node, Storm.Session, :get_request, [session, id])
  end
end
