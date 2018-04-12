defmodule Storm.Launcher.LauncherServer do
  use GenServer

  alias Storm.Dispatcher
  alias Storm.Simulation
  alias Storm.Simulation.Persistence

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init([simulation_id, session_id]) do
    state = Simulation.get_session(simulation_id, session_id)

    case state.state do
      :running ->
        schedule_start_clients()

      _ ->
        :ok
    end

    {:ok, state}
  end

  def handle_cast(:perform, %{state: :ready, id: id} = state) do
    Persistence.update_session(id, state: :running)
    schedule_start_clients()

    {:noreply, state}
  end
  def handle_cast(:perform, state) do
    {:noreply, state}
  end

  def handle_info(:start_clients, session) do
    schedule_start_clients()

    %{clients: clients, arrival_rate: arrival_rate,
      clients_started: started, dispatcher_pid: dispatcher} = session

    to_start = cond do
      started == clients -> 0
      started + arrival_rate < clients -> arrival_rate
      true -> clients - started
    end
    do_start_clients(dispatcher, session, to_start)
    Persistence.update_session(session.id, clients_started: started + to_start)

    {:noreply, %{session | clients_started: started + to_start}}
  end

  defp do_start_clients(_, _, 0), do: :ok
  defp do_start_clients(dispatcher, session, to_start) do
    %{id: session_id, simulation_id: simulation_id} = session
    ids = Simulation.get_ids(simulation_id, to_start)
    :ok = Dispatcher.start_clients(dispatcher, session_id, ids)
  end

  defp schedule_start_clients do
    Process.send_after(self(), :start_clients, :timer.seconds(1))
  end
end
