defmodule Storm.FuryBridge do
  @callback start_simulation(term, term) :: :ok | {:error, term}

  @callback start_clients(pid, term, Range.t) :: :ok | {:error, term}

  @callback terminate(pid) :: :ok | {:error, term}
end
