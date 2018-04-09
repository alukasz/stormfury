defmodule Db do
  @moduledoc """
  Documentation for Db.
  """

  alias Db.Table

  @tables [
    Db.Simulation,
    Db.Session
  ]

  def created? do
    Enum.all?(@tables, &Table.exists?/1)
  end
end
