defmodule Db.TableTest do
  use ExUnit.Case, async: true

  alias Db.Table

  defstruct [:id, :field]

  describe "create_from_struct/2" do
    test "creates mnesia table based on struct" do
      Table.create_from_struct(%__MODULE__{})

      assert __MODULE__ in :mnesia.system_info(:tables)
    end
  end

  describe "exists?/1" do
    test "when table exists" do
      {:atomic, :ok} = :mnesia.create_table(:test_table, [])

      assert Table.exists?(:test_table)
    end

    test "when table does not exist" do
      refute Table.exists?(:not_test_table)
    end
  end
end
