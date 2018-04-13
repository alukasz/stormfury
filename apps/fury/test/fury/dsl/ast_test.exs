defmodule Fury.DSL.ASTTest do
  use ExUnit.Case, async: true

  alias Fury.DSL.AST

  describe "build/1" do
    test "returns AST of given DSL" do
      dsl = """
      for i in 1..10 do
        think 10
        push "hello world"
      end
      """

      assert AST.build(dsl) == {:ok, ast_tokens()}
    end

    test "returns error tuple on invalid DSL syntax" do
      dsl = """
      push {"body": {"foo", "bar"}}
      think 1000
      """

      assert AST.build(dsl) == {:error, {"syntax error before: ','", 1}}
    end

    test "returns error tuple on illegal character" do
      dsl = """
      push ("body": ("foo", "bar"))
      think 1000
      """

      assert AST.build(dsl) == {:error, {"illegal character: '('", 1}}
    end
  end

  describe "traverse/3" do
    test "performs depth first traversal of AST" do
      AST.traverse ast_tokens(), fn ast, _ -> send(self(), ast) end

      assert_receive {:for, _}
      assert_receive {:in, _}
      assert_receive {:var, _}
      assert_receive {:range, _}
      assert_receive {:block, _}
      assert_receive {:think, _}
      assert_receive {:push, _}
    end

    test "carries accumulator over each form" do
      assert AST.traverse(ast_tokens(), 0, fn _, acc -> acc + 1 end) == 7
    end
  end

  describe "transform/2" do
    test "performs depth first traversal of AST" do
      AST.transform ast_tokens(), fn ast ->
        send(self(), ast)
      end

      assert_receive {:for, _}
      assert_receive {:in, _}
      assert_receive {:var, _}
      assert_receive {:range, _}
      assert_receive {:block, _}
      assert_receive {:think, _}
      assert_receive {:push, _}
    end

    test "replaces AST nodes with value returned by mapper" do
      mapper = fn
        {:push, _} -> {:push, ["updated data"]}
        {:block, block} -> {:block, block ++ block}
        ast -> ast
      end

      assert AST.transform([block: [think: [10], push: "data"]], mapper) ==
        [
          block: [
            think: [10],
            push: ["updated data"],
            think: [10],
            push: ["updated data"]
          ]
        ]
    end
  end

  defp ast_tokens do
    [
      for: [
        in: [
          var: ["i"],
          range: [1, 10]
        ],
        block: [
          think: [10],
          push: ["hello world"]
        ]
      ]
    ]
  end
end
