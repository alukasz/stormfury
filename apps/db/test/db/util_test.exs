defmodule Db.UtilTest do
  use ExUnit.Case, async: true

  alias Db.Util
  alias Db.TestStruct

  describe "match_spec/3" do
    test "builds match spec" do
      assert Util.match_spec(%TestStruct{}, :bar, "better bar") ==
        {TestStruct, :_, "better bar", :_, :_}
    end
  end

  describe "match_spec/2" do
    test "builds match spec" do
      assert Util.match_spec(%TestStruct{}, bar: "bar", foo: "foo") ==
      {TestStruct, :_, "bar", :_, "foo"}
    end
  end
end
