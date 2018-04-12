defmodule Db.RecordTest do
  use ExUnit.Case, async: true

  alias Db.Record
  alias Db.TestStruct

  defmodule InvalidRecord do
    defstruct [:foo, :bar]
  end

  describe "from_struct/1" do
    test "converts struct to record" do
      assert Record.from_struct(%TestStruct{}) ==
        TestStruct.record()
    end

    test "struct must have :id key" do
      assert catch_error(Record.from_struct(%InvalidRecord{}))
    end
  end

  describe "to_struct/1" do
    test "converts record to struct" do
      assert Record.to_struct(TestStruct.record()) ==
        %TestStruct{}
    end

    test "record must be tuple" do
      assert catch_error(Record.to_struct([:foo, :bar]))
    end

    test "first element of record must be an atom" do
      assert catch_error(Record.to_struct(["foo", :bar]))
    end
  end

  describe "record_keys/1" do
    test "converts struct to list of keys of record" do
      assert Record.record_keys(%TestStruct{}) ==
        [:id, :bar, :baz, :foo]
    end

    test "converts record to list of keys of record" do
      assert Record.record_keys(TestStruct.record()) ==
        [:id, :bar, :baz, :foo]
    end
  end
end
