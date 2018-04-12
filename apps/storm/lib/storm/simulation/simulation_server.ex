defmodule Storm.Simulation.SimulationServer do
  use GenServer

  alias Storm.Launcher
  alias Storm.Simulation
  alias Storm.RemoteSimulation
  alias Storm.Simulation.Persistence

  require Logger

  def start_link([simulation_id, _] = opts) do
    GenServer.start_link(__MODULE__, opts, name: name(simulation_id))
  end

  defp name(id) do
    Simulation.name(id)
  end

  def init(opts) do
    state = fetch_state(opts)
    do_init(state)
    Logger.metadata(simulation: state.id)

    {:ok, state}
  end

  defp fetch_state(%{id: id} = state) do
    %{Persistence.get_simulation(id) |
      supervisor_pid: state.supervisor_pid,
      dispatcher_pid: state.dispatcher_pid,
      launchers_pids: state.launchers_pids
    }
  end
  defp fetch_state([simulation_id, supervisor_pid]) do
    fetch_state(%Simulation{
      id: simulation_id,
      supervisor_pid: supervisor_pid
    })
  end

  defp do_init(%{state: :ready}) do
    Process.send_after(self(), :initialize, 500)
  end
  defp do_init(%{state: :running}) do
    Process.send_after(self(), :perform, 100)
  end

  def handle_call(:set_dispatcher, {dispatcher_pid, _}, state) do
    {:reply, :ok, %{state | dispatcher_pid: dispatcher_pid}}
  end
  def handle_call({:get_session, session_id}, {pid, _}, state) do
    session =
      session_id
      |> Persistence.get_session(state.id)
      |> Map.put(:dispatcher_pid, state.dispatcher_pid)

    {:reply, session, add_session_pid(state, pid)}
  end
  def handle_call({:get_ids, number}, _, state) do
    {ids, state} = get_ids(state, number)
    Persistence.update_simulation(
      state.id,
      clients_started: state.clients_started
    )

    {:reply, ids, state}
  end

  def handle_info(:initialize, %{id: id} = state) do
    RemoteSimulation.start(state)
    Persistence.update_simulation(id, state: :running)
    send(self(), :perform)

    {:noreply, %{state | state: :running}}
  end
  def handle_info(:perform, %{duration: duration} = state) do
    Logger.info("Starting simulation")
    Process.send_after(self(), :cleanup, :timer.seconds(duration))
    turn_launchers(state)

    {:noreply, state}
  end
  def handle_info(:cleanup, %{id: id} = state) do
    Logger.info("Simulation finished, terminating")
    Persistence.update_simulation(id, state: :finished)
    RemoteSimulation.terminate(state)
    spawn fn ->
      Simulation.terminate(state.supervisor_pid)
    end

    {:noreply, state}
  end

  defp add_session_pid(state, pid) do
    Map.update(state, :launchers_pids, [], fn pids -> [pid | pids] end)
  end

  defp get_ids(%{clients_started: started} = state, number) do
    new_started = started + number
    ids = (started + 1)..new_started

    {ids, %{state | clients_started: new_started}}
  end

  defp turn_launchers(%{launchers_pids: pids}) do
    Enum.each(pids, &Launcher.perform/1)
  end
end
