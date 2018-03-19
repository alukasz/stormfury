defmodule Db.TestStruct do
  defstruct foo: "foo", bar: "bar", baz: "baz", id: "id"

  def record do
    {__MODULE__, "id", "bar", "baz", "foo"}
  end
end
