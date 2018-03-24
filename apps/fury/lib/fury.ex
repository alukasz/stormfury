defmodule Fury do
  alias Fury.Session

  def start_sessions(simulation_id) do
    case Db.Simulation.get(simulation_id) do
      nil ->
        {:error, "Simulation with id #{simulation_id} not found"}

      simulation ->
        do_start_sessions(simulation)
        :ok
    end
  end

  defp do_start_sessions(%Db.Simulation{sessions: sessions} = simulation) do
    sessions
    |> Enum.map(&Session.new(&1, simulation))
  end
end
