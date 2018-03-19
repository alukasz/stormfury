defmodule Db.Record do
  defguard is_record(record) when is_tuple(record) and is_atom(elem(record, 0))

  def from_struct(%mod{} = struct) do
    List.to_tuple([mod | record_values(struct)])
  end

  def to_struct(record) when is_record(record) do
    struct_mod = record_name(record)

    record
    |> record_keys()
    |> Enum.zip(record_values(record))
    |> struct_mod.__struct__()
  end

  def record_keys(%_{} = struct) do
    fields =
      struct
      |> Map.from_struct()
      |> Map.delete(:id)
      |> Map.keys()
      |> Enum.sort()

    [:id | fields]
  end
  def record_keys(record) when is_record(record) do
    record
    |> record_name()
    |> struct()
    |> record_keys()
  end

  defp record_name(record) do
    elem(record, 0)
  end

  defp record_values(%_{} = struct) do
    {id, rest} = Map.pop(struct, :id)
    fields =
      rest
      |> Map.from_struct()
      |> Enum.sort_by(&elem(&1, 0))
      |> Keyword.values()

    [id | fields]
  end

  defp record_values(record) when is_record(record) do
    record
    |> Tuple.to_list()
    |> tl()
  end
end
