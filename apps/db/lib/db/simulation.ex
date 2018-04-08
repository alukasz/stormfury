defmodule Db.Simulation do
  alias Db.Repo
  alias Db.Session
  alias Db.Simulation

  defstruct [
    :id,
    :url,
    :duration,
    :protocol_mod,
    :transport_mod,
    sessions: [],
    clients_started: 0
  ]

  def get(id) do
    transaction = fn ->
      case Repo.get(Simulation, id) do
        nil ->
          nil

        simulation ->
          %{simulation | sessions: Session.get_by_simulation_id(id)}
      end
    end

    Repo.transaction(transaction)
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

  def update(%Simulation{id: id}, attrs) do
    Repo.update(Simulation, id, attrs)
  end

  defp insert_sessions(sessions) do
    sessions
    |> Enum.map(&Session.insert/1)
    |> Enum.find(:ok, fn
      {:error, _} -> true
      _ -> false
    end)
  end
end
