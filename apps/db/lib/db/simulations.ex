defmodule Db.Simulations do
  alias Db.Repo
  alias Db.Util
  alias Storm.Session
  alias Storm.Simulation

  def get(id) do
    transaction = fn ->
      case Repo.get(Simulation, id) do
        nil ->
          nil

        simulation ->
          %{simulation | sessions: get_sessions(simulation)}
      end
    end

    Repo.transaction(transaction)
  end

  defp get_sessions(%Simulation{id: id}) do
    %Session{}
    |> Util.match_spec(:simulation_id, id)
    |> Repo.match()
  end

  def insert(%Simulation{sessions: sessions} = simulation) do
    transaction = fn ->
      case Repo.insert(%{simulation | sessions: []}) do
        :ok ->
          insert_sessions(sessions)

        error ->
          error
      end
    end

    Repo.transaction(transaction)
  end

  defp insert_sessions(sessions) do
    sessions
    |> Enum.map(&insert_session/1)
    |> Enum.find(:ok, fn
      {:error, _} -> true
      _ -> false
    end)
  end

  defp insert_session(%Session{} = session) do
    Repo.insert(session)
  end
  defp insert_session(arg) do
    Repo.abort_transaction("not a session #{inspect arg}")
  end
end
