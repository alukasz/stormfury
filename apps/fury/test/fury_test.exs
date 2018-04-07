defmodule FuryTest do
  use ExUnit.Case, async: true

  describe "group/1" do
    test "returns name for pg2 group" do
      assert Fury.group(:id) == {Fury.Simulations, :id}
    end
  end
end
