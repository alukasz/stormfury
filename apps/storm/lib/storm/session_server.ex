defmodule Storm.SessionServer do
  use GenServer

  alias Storm.Simulation
  alias Storm.Simulation.LoadBalancer

  @registry Storm.Session.Registry

  defmodule State do
    defstruct session: nil, clients_started: 0
  end

  def start_link(%{id: id} = session) do
    GenServer.start_link(__MODULE__, session, name: name(id))
  end

  def name(id) do
    {:via, Registry, {@registry, id}}
  end

  def init(session) do
    schedule_start_clients()

    {:ok, %State{session: session}}
  end

  def handle_call({:get_request, index}, _, %{session: session} = state) do
    reply =
      case Enum.at(session.scenario, index, :not_found) do
        :not_found -> {:error, :not_found}
        request -> {:ok, request}
      end

    {:reply, reply, state}
  end

  def handle_info(:start_clients, %{session: session} = state) do
    schedule_start_clients()

    %{id: session_id, simulation_id: simulation_id, clients: clients,
      arrival_rate: arrival_rate} = session
    started = state.clients_started

    to_start = cond do
      started == clients -> 0
      started + arrival_rate < clients -> arrival_rate
      true -> clients - started
    end
    do_start_clients(simulation_id, session_id, to_start)

    {:noreply, %{state | clients_started: started + to_start}}
  end

  defp do_start_clients(_, _, 0), do: :ok
  defp do_start_clients(simulation_id, session_id, to_start) do
    ids = Simulation.get_ids(simulation_id, to_start)
    LoadBalancer.start_clients(simulation_id, session_id, ids)
  end

  defp schedule_start_clients do
    Process.send_after(self(), :start_clients, :timer.seconds(1))
  end
end
