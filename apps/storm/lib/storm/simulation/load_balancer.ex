defmodule Storm.Simulation.LoadBalancer do
  alias Storm.Simulation.LoadBalancerServer

  def start_clients(simulation_id, session_id, ids) do
    clients =
      session_id
      |> List.wrap()
      |> Stream.cycle()
      |> Enum.zip(ids)
    message = {:add_clients, clients}

    GenServer.call(LoadBalancerServer.name(simulation_id), message)
  end
end
