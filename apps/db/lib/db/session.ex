defmodule Db.Session do
  alias Db.Repo
  alias Db.Session
  alias Db.Util

  defstruct [
    :id,
    :clients,
    :arrival_rate,
    :scenario,
    :simulation_id,
    clients_started: 0,
    state: :ready
  ]

  def get(id) do
    Repo.get(Session, id)
  end

  def insert(%Session{} = session) do
    Repo.insert(session)
  end

  def update(%Session{id: id}, attrs) do
    Repo.update(Session, id, attrs)
  end
  def update(id, attrs) do
    Repo.update(Session, id, attrs)
  end

  def get_by_simulation_id(simulation_id) do
    %Session{}
    |> Util.match_spec(:simulation_id, simulation_id)
    |> Repo.match()
  end
end
