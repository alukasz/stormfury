defmodule FuryTest do
  use ExUnit.Case
  doctest Fury

  test "greets the world" do
    assert Fury.hello() == :world
  end
end
