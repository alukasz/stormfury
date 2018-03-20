defmodule Storm.FuryBridge do
  @callback start_session(node, struct) :: :ok | {:error, term}

  @callback start_clients(node, term, Range.t) :: :ok | {:error, term}
end