defmodule Fury.DSL.ParserTest do
  use ExUnit.Case, async: true

  alias Fury.DSL.Parser

  describe "list" do
    test "empty list" do
      tokens = [{:push, 1}, {:"[", 1}, {:"]", 1}]

      assert Parser.parse(tokens) == {:ok, [{:push, [[]]}]}
    end

    test "single element list" do
      tokens = [{:push, 1}, {:"[", 1}, {:int, 1, 42}, {:"]", 1}]

      assert Parser.parse(tokens) == {:ok, [{:push, [[42]]}]}
    end

    test "multiple elements list" do
      tokens = [{:push, 1}, {:"[", 1},
                {:int, 1, 42}, {:",", 1},
                {:string, 1, "foo"}, {:",", 1},
                {:true, 1},
                {:"]", 1}]

      assert Parser.parse(tokens) == {:ok, [{:push, [[42, "foo", true]]}]}
    end
  end

  describe "map" do
    test "empty map" do
      tokens = [{:push, 1}, {:"{", 1}, {:"}", 1}]

      assert Parser.parse(tokens) == {:ok, [{:push, [%{}]}]}
    end

    test "single element map" do
      tokens = [{:push, 1}, {:"{", 1},
                {:string, 1, "foo"}, {:":", 1}, {:int, 1, 42},
                {:"}", 1}]

      assert Parser.parse(tokens) == {:ok, [{:push, [%{"foo" => 42}]}]}
    end

    test "multiple elements map" do
      tokens = [{:push, 1}, {:"{", 1},
                {:string, 1, "foo"}, {:":", 1}, {:int, 1, 42}, {:",", 1},
                {:string, 1, "bar"}, {:":", 1}, {:int, 1, 42}, {:",", 1},
                {:string, 1, "baz"}, {:":", 1}, {:int, 1, 42},
                {:"}", 1}]

      assert Parser.parse(tokens) ==
        {:ok, [{:push, [%{"foo" => 42, "bar" => 42, "baz" => 42}]}]}
    end
  end

  describe "push" do
    test "AST is {push, args}" do
      tokens = [{:push, 1}, {:string, 1, "foo"}]

      assert Parser.parse(tokens) == {:ok, [{:push, ["foo"]}]}
    end

    test "requires 1 argument" do
      tokens = [{:push, 1}]

      assert Parser.parse(tokens) == syntax_error("")
    end
  end

  describe "think" do
    test "AST is {think, args}" do
      tokens = [{:think, 1}, {:int, 1, 42}]

      assert Parser.parse(tokens) == {:ok, [{:think, [42]}]}
    end

    test "requires 1 argument" do
      tokens = [{:think, 1}]

      assert Parser.parse(tokens) == syntax_error("")
    end
  end

  describe "for" do
    test "AST is {for, [in, block]}" do
      tokens = [{:for, 1}, {:identifier, 1, "i"}, {:in, 1},
                {:int, 1, 1}, {:.., 1}, {:int, 1, 10},
                {:do, 1}, {:end, 1}]

      assert Parser.parse(tokens) ==
        {:ok, [
          {:for, [
            {:in, [{:var, ["i"]}, {:range, [1, 10]}]},
            {:block, []}
          ]}
        ]}
    end

    test "works with list" do
      tokens = [{:for, 1}, {:identifier, 1, "i"}, {:in, 1},
                {:"[", 1}, {:int, 1, 1}, {:","}, {:int, 1, 2}, {:"]", 1},
                {:do, 1}, {:end, 1}]

      assert Parser.parse(tokens) ==
        {:ok, [
          {:for, [
              {:in, [{:var, ["i"]}, {:list, [1, 2]}]},
              {:block, []}
            ]}
        ]}
    end

    test "requires variable and range" do
      tokens = [{:for, 1}, {:do, 1}, {:end, 1}]

      assert Parser.parse(tokens) == syntax_error("do")
    end

    test "requires block" do
      tokens = [{:for, 1}, {:identifier, 1, "i"}, {:in, 1},
                {:int, 1, 1}, {:.., 1}, {:int, 1, 10}]

      assert Parser.parse(tokens) == syntax_error("")
    end
  end

  test "invalid syntax results in error" do
    tokens = [{:"<", 1}, {:">", 1}]

    assert Parser.parse(tokens) == syntax_error("'<'")
  end

  defp syntax_error(token, line \\ 1) do
    {:error, {"syntax error before: #{token}", line}}
  end
end
