defmodule Db.Table do
  alias Db.Record

  def create_from_struct(%mod{} = struct, opts \\ []) do
    opts = [{:attributes, table_attributes(struct)} | opts]
    IO.inspect opts
    :mnesia.create_table(mod, opts)
  end

  defp table_attributes(struct) do
    fields =
      struct
      |> Map.from_struct()
      |> Map.delete(:id)
      |> Map.keys()
      |> Enum.sort

    [:id | fields]
  end
end
