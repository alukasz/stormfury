defmodule Storm.Launcher.LauncherServer do
  use GenServer

  alias Storm.Dispatcher
  alias Storm.Launcher
  alias Storm.Simulation

  defmodule State do
    defstruct [
      :simulation_id,
      :session
    ]

    def new([simulation_id, session_id]) do
      %State{
        simulation_id: simulation_id,
        session: Db.Session.get(session_id)
      }
    end
  end

  def start_link(simulation_id, session_id) do
    opts = [simulation_id, session_id]

    GenServer.start_link(__MODULE__, opts, name: name(session_id))
  end

  def init(opts) do
    {:ok, State.new(opts)}
  end

  def handle_call(:perform, _from, state) do
    schedule_start_clients()

    {:reply, :ok, state}
  end

  def handle_info(:start_clients, state) do
    schedule_start_clients()

    %{simulation_id: simulation_id,
      session: %{id: session_id} = session} = state
    %{clients: clients, arrival_rate: arrival_rate,
      clients_started: started} = session

    to_start = cond do
      started == clients -> 0
      started + arrival_rate < clients -> arrival_rate
      true -> clients - started
    end
    do_start_clients(simulation_id, session_id, to_start)

    session = %{session | clients_started: started + to_start}

    {:noreply, %{state | session: session}}
  end

  defp do_start_clients(_, _, 0), do: :ok
  defp do_start_clients(simulation_id, session_id, to_start) do
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
