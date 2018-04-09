defmodule Storm.Simulation.SimulationServer do
  use GenServer

  alias Storm.Simulation
  alias Storm.Launcher

  require Logger

  @fury_bridge Application.get_env(:storm, :fury_bridge)

  def start_link(%Db.Simulation{id: id}) do
    GenServer.start_link(__MODULE__, id, name: name(id))
  end

  def init(id) do
    Logger.metadata(simulation: id)
    Logger.info("Initializing simulation")
    Process.send_after(self(), :initialize, 50)

    {:ok, Db.Simulation.get(id)}
  end

  def handle_call({:get_ids, number}, _, %{clients_started: started} = simulation) do
    new_started = started + number
    range = (started + 1)..new_started
    simulation = Db.Simulation.update(simulation, clients_started: new_started)

    {:reply, range, simulation}
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

  defp translate_simulation(%{sessions: sessions} = simulation) do
    data = Map.from_struct(simulation)
    simulation = struct(Fury.Simulation, data)
    %{simulation | sessions: Enum.map(sessions, &translate_session/1)}
  end

  defp translate_session(session) do
    data = Map.from_struct(session)
    struct(Fury.Session, data)
  end

  defp turn_launchers(%{sessions: sessions}) do
    Enum.each(sessions, &Launcher.perform(&1.id))
  end

  defp name(id) do
    Simulation.name(id)
  end
end
