defmodule StormTest do
  use ExUnit.Case
  doctest Storm

  test "greets the world" do
    assert Storm.hello() == :world
  end
end
