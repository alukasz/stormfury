defmodule Fury.Storm do
  @storm_server {:global, Storm.Server}

  def send_metrics(simulation_id, metrics) do
    request = {:metrics, simulation_id, metrics}

    GenServer.cast(@storm_server, request)
  end
end
