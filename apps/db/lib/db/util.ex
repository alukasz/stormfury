defmodule Db.Util do
  alias Db.Record

  def match_spec(%_{} = struct, field, value) do
    match_spec(struct, [{field, value}])
  end

  def match_spec(%_{} = struct, pairs) do
    match_spec = empty_match_spec(struct)
    Enum.reduce pairs, match_spec, fn {field, value}, match_spec ->
      put_elem(match_spec, get_field_position(struct, field), value)
    end
  end

  defp empty_match_spec(%mod{} = struct) do
    List.to_tuple([mod | List.duplicate(:_, map_size(struct) - 1)])
  end

  defp get_field_position(struct, field) do
    struct
    |> Record.record_keys()
    |> Enum.find_index(&(&1 == field))
    |> Kernel.+(1) # make up for record name
  end
end
