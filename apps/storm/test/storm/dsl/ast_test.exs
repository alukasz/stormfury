defmodule Storm.DSL.ASTTest do
  use ExUnit.Case, async: true

  alias Storm.DSL.AST

  describe "build/1" do
    test "returns AST of given DSL" do
      dsl = """
      for i in 1..10 do
        connect
        push "hello world"
      end
      """

      assert AST.build(dsl) == ast_tokens()
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
      assert_receive {:.., _}
      assert_receive {:block, _}
      assert_receive {:connect, _}
      assert_receive {:push, _}
    end

    test "carries accumulator over each form" do
      assert AST.traverse(ast_tokens(), 0, fn _, acc -> acc + 1 end) == 7
    end
  end

  defp ast_tokens do
    [
      for: [
        in: [
          var: ["i"],
          ..: [1, 10]
        ],
        block: [
          connect: [],
          push: ["hello world"]
        ]
      ]
    ]
  end
end
