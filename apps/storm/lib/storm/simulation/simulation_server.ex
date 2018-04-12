defmodule Storm.Simulation.SimulationServer do
  use GenServer

  alias Storm.Launcher
  alias Storm.Simulation
  alias Storm.Simulation.Persistence

  require Logger

  @fury_bridge Application.get_env(:storm, :fury_bridge)

  def start_link([simulation_id, _] = opts) do
    GenServer.start_link(__MODULE__, opts, name: name(simulation_id))
  end

  def init([simulation_id, supervisor_pid]) do
    Logger.metadata(simulation: simulation_id)
    Logger.info("Starting SimulationServer")

    state =
      simulation_id
      |> Persistence.get_simulation()
      |> Map.put(:supervisor_pid, supervisor_pid)

    {:ok, state}
  end

  def handle_call(:set_dispatcher, {dispatcher_pid, _}, state) do
    {:reply, :ok, %{state | dispatcher_pid: dispatcher_pid}}
  end
  def handle_call({:get_session, session_id}, {session_pid, _}, state) do
    %{dispatcher_pid: dispatcher_pid, sessions_pids: sessions_pids} = state
    session =
      state
      |> find_session(session_id)
      |> Map.put(:dispatcher_pid, dispatcher_pid)

    {:reply, session, %{state | sessions_pids: [session_pid | sessions_pids]}}
  end
  def handle_call({:get_ids, number}, _, %{clients_started: started} = state) do
    new_started = started + number
    ids = (started + 1)..new_started
    Persistence.update_simulation(state.id, clients_started: new_started)

    {:reply, ids, %{state| clients_started: new_started}}
  end

  defp find_session(%{sessions: sessions}, session_id) do
    Enum.find sessions, fn
      %{id: ^session_id} -> true
      _ -> false
    end
  end

  def handle_info(:initialize, simulation) do
    create_group(simulation)
    start_remote_simulations(simulation)
    send(self(), :perform)

    {:noreply, simulation}
  end
  def handle_info(:perform, %{duration: duration} = simulation) do
    Logger.info("Starting simulation")
    timeout = :timer.seconds(duration)
    Process.send_after(self(), :cleanup, timeout)
    turn_launchers(simulation)

    {:noreply, simulation}
  end
  def handle_info(:cleanup, simulation) do
    Logger.info("Simulation finished, terminating")
    stop_remote_simulations(simulation)
    stop_simulation(simulation)

    {:noreply, simulation}
  end

  defp create_group(%{id: id}) do
    :pg2.create(Fury.group(id))
  end

  defp get_group_members(%{id: id}) do
    :pg2.get_members(Fury.group(id))
  end

  defp start_remote_simulations(simulation) do
    simulation
    |> translate_simulation()
    |> @fury_bridge.start_simulation()
    |> report_failed_nodes()
  end

  defp report_failed_nodes({success, failed}) do
    Enum.each success, fn
      {node, {:error, reason}} ->
        Logger.error("Failed to start simulation on node #{inspect node}, reason: #{inspect reason}")

      _ ->
        :ok
    end

    case failed do
      [] ->
        :ok

      nodes ->
        Logger.error("Failed to start simulations on nodes #{inspect nodes}")
    end
  end

  defp stop_remote_simulations(simulation) do
    simulation
    |> get_group_members()
    |> Enum.map(&GenServer.call(&1, :terminate))
  end

  defp stop_simulation(%{supervisor_pid: pid}) do
    Simulation.terminate(pid)
  end

  defp translate_simulation(%{sessions: sessions} = simulation) do
    data = Map.from_struct(simulation)
    simulation = struct(Fury.Simulation, data)
    %{simulation | sessions: Enum.map(sessions, &translate_session/1)}
  end

  defp translate_session(session) do
    data = Map.from_struct(session)
    struct(Fury.Session, data)
  end

  defp turn_launchers(%{sessions_pids: pids}) do
    Enum.each(pids, &Launcher.perform/1)
  end

  defp name(id) do
    Simulation.name(id)
  end
end
