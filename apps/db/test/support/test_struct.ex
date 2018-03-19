defmodule Db.TestStruct do
  defstruct foo: "foo", bar: "bar", baz: "baz", id: "id"

  def record(args \\ []) do
    {
      __MODULE__,
      Keyword.get(args, :id, "id"),
      Keyword.get(args, :bar, "bar"),
      Keyword.get(args, :baz, "baz"),
      Keyword.get(args, :foo, "foo"),
    }
  end
end
