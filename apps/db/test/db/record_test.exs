defmodule Db.RecordTest do
  use ExUnit.Case, async: true

  alias Db.Record

  defmodule Example do
    defstruct id: "id", foo: "foo", bar: "bar", baz: "baz"
  end

  describe "from_struct/1" do
    test "converts struct to record" do
      assert Record.from_struct(%Example{}) ==
        {Example, "id", "bar", "baz", "foo"}
    end
  end

  describe "to_struct/1" do
    test "converts record to struct" do
      assert Record.to_struct({Example, "id", "bar", "baz", "foo"}) ==
        %Example{}
    end
  end
end
