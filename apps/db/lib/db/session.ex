defmodule Db.Session do
  defstruct [
    :id,
    :clients,
    :arrival_rate,
    :scenario,
    :simulation_id
  ]
end
