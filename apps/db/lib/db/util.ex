defmodule Db.Util do
  alias Db.Record

  def match_spec(%_{} = struct, field, value) do
    struct
    |> empty_match_spec()
    |> put_elem(get_field_position(struct, field), value)
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
