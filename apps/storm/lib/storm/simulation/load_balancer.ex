defmodule Storm.Simulation.LoadBalancer do
  alias Storm.Simulation.LoadBalancerServer

  def start_clients(simulation_id, session_id, clients) do
    message = {:start_clients, session_id, clients}

    GenServer.call(LoadBalancerServer.name(simulation_id), message)
  end
end
