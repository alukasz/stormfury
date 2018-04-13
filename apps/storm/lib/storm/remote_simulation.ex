defmodule Storm.RemoteSimulation do
  require Logger

  @fury_bridge Application.get_env(:storm, :fury_bridge)

  def start(simulation) do
    sessions =
      simulation
      |> create_group()
      |> translate_sessions()

    @fury_bridge.start_simulation(simulation.id, sessions)
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

  defp translate_sessions(%{sessions: sessions} = simulation) do
    Enum.map(sessions, &translate_session(&1, simulation))
  end

  defp translate_session(session, simulation) do
    %Fury.Session{
      id: session.id,
      simulation_id: simulation.id,
      url: simulation.url,
      protocol_mod: simulation.protocol_mod,
      transport_mod: simulation.transport_mod,
      scenario: session.scenario
    }
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
