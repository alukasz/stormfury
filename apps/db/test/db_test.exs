defmodule DbTest do
  use ExUnit.Case

  describe "created?" do
    test "checks if all tables are created" do
      assert Db.created?()
    end
  end
end
