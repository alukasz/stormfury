defmodule Storm.Launcher.LauncherServer do
  use GenServer

  alias Storm.Dispatcher
  alias Storm.Launcher
  alias Storm.Simulation

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init([session_id, dispatcher]) do
    session = Db.Session.get(session_id)

    {:ok, %{session | dispatcher: dispatcher}}
  end

  def handle_call(:perform, _from, session) do
    schedule_start_clients()

    {:reply, :ok, session}
  end

  def handle_info(:start_clients, session) do
    schedule_start_clients()

    %{clients: clients, arrival_rate: arrival_rate,
      clients_started: started} = session

    to_start = cond do
      started == clients -> 0
      started + arrival_rate < clients -> arrival_rate
      true -> clients - started
    end
    do_start_clients(session, to_start)
    session = Db.Session.update(session, clients_started: started + to_start)

    {:noreply, session}
  end

  defp do_start_clients(_, 0), do: :ok
  defp do_start_clients(session, to_start) do
    %{id: session_id, simulation_id: simulation_id} = session
    ids = Simulation.get_ids(simulation_id, to_start)
    :ok = Dispatcher.start_clients(simulation_id, session_id, ids)
  end

  defp schedule_start_clients do
    Process.send_after(self(), :start_clients, :timer.seconds(1))
  end

  defp name(session_id) do
    Launcher.name(session_id)
  end
end
