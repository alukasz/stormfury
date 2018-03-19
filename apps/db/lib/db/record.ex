defmodule Db.Record do
  def from_struct(%mod{} = struct) do
    map = Map.from_struct(struct)

    List.to_tuple([mod | record_fields(map)])
  end

  def to_struct(record) when is_tuple(record) and is_atom(elem(record, 0)) do
    struct_mod = record_struct_mod(record)

    record
    |> record_keys()
    |> Enum.zip(record_values(record))
    |> struct_mod.__struct__()
  end

  defp record_fields(map) do
    {id, rest} = Map.pop(map, :id)
    fields =
      rest
      |> Enum.sort_by(&elem(&1, 0))
      |> Keyword.values()
    [id | fields]
  end

  defp record_struct_mod(record) do
    elem(record, 0)
  end

  defp record_keys(record) do
    fields = record
    |> record_struct_mod()
    |> struct()
    |> Map.from_struct()
    |> Map.delete(:id)
    |> Map.keys()
    |> Enum.sort()

    [:id | fields]
  end

  defp record_values(record) do
    record
    |> Tuple.to_list()
    |> tl()
  end
end
