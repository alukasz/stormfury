defmodule Storm.DSLTest do
  use ExUnit.Case, async: true

  alias Storm.DSL

  describe "parse/1" do
    test "transform expressions" do
      dsl = """
      push "hello"
      think 10
      """

      assert DSL.parse(dsl) ==
        {:ok, [{:push, "hello"}, {:think, 10}]}
    end

    test "loop" do
      dsl = "for i in 1..2 do push {\"body\":\"{{i}}\"} end"

      assert DSL.parse(dsl) ==
        {:ok, [push: "{\"body\":\"1\"}", push: "{\"body\":\"2\"}"]}
    end

    test "nested loop" do
      dsl = """
      for i in 1..2 do
        for j in [3, 4] do
          push "{{i}}-{{j}}"
        end
      end
      """

      assert DSL.parse(dsl) ==
        {:ok, [push: "1-3", push: "1-4", push: "2-3", push: "2-4"]}
    end

    test "returns error tuple on syntax error" do
      dsl = "for i in ..2 do end"

      assert DSL.parse(dsl) == {:error, {"syntax error before: '..'", 1}}
    end
  end
end
