defmodule Storm.FuryBridge do
  @callback start_simulation(term) :: :ok | {:error, term}

  @callback start_clients(node, term, Range.t) :: :ok | {:error, term}
end
