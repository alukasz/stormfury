defmodule Storm.RemoteSimulation do
  require Logger

  @fury_bridge Application.get_env(:storm, :fury_bridge)

  def start(simulation) do
    simulation
    |> create_group()
    |> translate_simulation()
    |> @fury_bridge.start_simulation()
    |> report_failed_nodes()
  end

  def terminate(simulation) do
    simulation
    |> get_group_members()
    |> Enum.map(&GenServer.call(&1, :terminate))
  end

  defp create_group(%{id: id} = simulation) do
    :pg2.create(Fury.group(id))

    simulation
  end

  defp get_group_members(%{id: id}) do
    :pg2.get_members(Fury.group(id))
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
end
