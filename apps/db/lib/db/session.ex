defmodule Db.Session do
  alias Db.Repo
  alias Db.Session
  alias Db.Util

  defstruct [
    :id,
    :clients,
    :arrival_rate,
    :scenario,
    :simulation_id
  ]

  def insert(%Session{} = session) do
    Repo.insert(session)
  end

  def get_by_simulation_id(simulation_id) do
    %Session{}
    |> Util.match_spec(:simulation_id, simulation_id)
    |> Repo.match()
  end
end
