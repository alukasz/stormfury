defmodule Db.RepoTest do
  use Db.MnesiaCase

  alias Db.Repo
  alias Db.TestStruct

  defmodule SpookyStruct do
    defstruct [:field]
  end

  describe "get/2" do
    test "returns struct from database" do
      insert_record(TestStruct.record(id: 42))

      assert Repo.get(TestStruct, 42) == %TestStruct{id: 42}
    end

    test "returns null when record does not exist" do
      assert Repo.get(TestStruct, 42) == nil
    end

    test "returns error tuple when table does not exist" do
      assert {:error, _} = Repo.get(SpookyTable, 42)
    end
  end

  describe "insert/1" do
    test "inserts struct into database" do
      assert :ok = Repo.insert(%TestStruct{id: 43})

      assert record_exists?(TestStruct, 43)
    end

    test "returns error tuple when table does not exist" do
      assert {:error, _} = Repo.insert(%SpookyStruct{})
    end
  end

  describe "match/1" do
    test "returns structs that matches" do
      insert_record(TestStruct.record(id: 1, foo: "no match"))
      insert_record(TestStruct.record(id: 2, foo: "will match"))
      insert_record(TestStruct.record(id: 3, foo: "will match"))
      insert_record(TestStruct.record(id: 4, foo: "no match"))

      records = Repo.match({TestStruct, :_, :_, :_, "will match"})

      assert records |> Enum.map(&(&1.id)) |> Enum.sort() == [2, 3]
    end

    test "returns empty list when no matches" do
      insert_record(TestStruct.record(id: 1, foo: "no match"))

      assert [] = Repo.match({TestStruct, :_, :_, :_, "will match"})
    end
  end

  describe "transaction/1" do
    test "performs operation inside transaction" do
      transaction = fn -> :mnesia.write(TestStruct.record(id: 42)) end

      assert :ok = Repo.transaction(transaction)

      assert record_exists?(TestStruct, 42)
    end
  end
end
