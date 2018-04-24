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
    do_init(state)

    {:ok, state}
  end

  defp do_init(%{state: :running}) do
    schedule_start_clients()
  end
  defp do_init(_) do
    :ok
  end

  def handle_cast(:perform, %{state: :ready, id: id} = state) do
    Persistence.update_session(id, state: :running)
    schedule_start_clients()

    {:noreply, %{state | state: :running}}
  end
  def handle_cast(:perform, state) do
    {:noreply, state}
  end

  def handle_info(:start_clients, state) do
    schedule_start_clients()

    {to_start, started} = calculate_clients_to_start(state)
    do_start_clients(state, to_start)
    Persistence.update_session(state.id, clients_started: started)

    {:noreply, %{state | clients_started: started}}
  end

  defp calculate_clients_to_start(state) do
    %{clients: clients, arrival_rate: arrival_rate,
      clients_started: started} = state

    to_start =
      cond do
        started >= clients -> 0
        started + arrival_rate < clients -> arrival_rate
        true -> clients - started
      end
    {to_start, started + to_start}
  end

  defp do_start_clients(_, 0), do: :ok
  defp do_start_clients(state, to_start) do
    %{id: state_id, simulation_id: simulation_id} = state
    ids = Simulation.get_ids(simulation_id, to_start)
    :ok = Dispatcher.start_clients(state.dispatcher_pid, state_id, ids)
  end

  defp schedule_start_clients do
    Process.send_after(self(), :start_clients, :timer.seconds(1))
  end
end
