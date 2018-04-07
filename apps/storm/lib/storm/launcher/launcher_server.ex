defmodule Storm.Launcher.LauncherServer do
  use GenServer

  alias Storm.Simulation
  alias Storm.Dispatcher

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

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    schedule_start_clients()

    {:ok, State.new(opts)}
  end

  def handle_info(:start_clients, state) do
    %{simulation_id: simulation_id,
      session: %{id: session_id} = session} = state
    %{clients: clients, arrival_rate: arrival_rate,
      clients_started: started} = session

    to_start = cond do
      started == clients -> 0
      started + arrival_rate < clients -> arrival_rate
      true -> clients - started
    end
    ids = Simulation.get_ids(simulation_id, to_start)
    :ok = Dispatcher.start_clients(simulation_id, session_id, ids)
    session = %{session | clients_started: started + to_start}

    {:noreply, %{state | session: session}}
  end

  defp schedule_start_clients do
    Process.send_after(self(), :start_clients, :timer.seconds(1))
  end
end
