defmodule Db.TestDb do
  @tables [
    Db.TestStruct,
    Db.Simulation,
    Db.Session
  ]

  def create do
    existing_tables = :mnesia.system_info(:tables)
    Enum.each @tables, fn table ->
      unless table in existing_tables, do: create_table(table)
    end
  end

  defp create_table(table) do
    table
    |> struct()
    |> Db.Table.create_from_struct()
  end
end
