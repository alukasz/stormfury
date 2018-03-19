defmodule Db.RecordTest do
  use ExUnit.Case, async: true

  alias Db.Record
  alias Db.TestStruct

  describe "from_struct/1" do
    test "converts struct to record" do
      assert Record.from_struct(%TestStruct{}) ==
        TestStruct.record()
    end
  end

  describe "to_struct/1" do
    test "converts record to struct" do
      assert Record.to_struct(TestStruct.record()) ==
        %TestStruct{}
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
