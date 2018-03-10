defmodule Storm.DSL do
  alias Storm.DSL.AST
  alias Storm.DSL.Scenario

  def parse(dsl) do
    with {:ok, ast} <- AST.build(dsl) do
      Scenario.build(ast)
    else
      error -> error
    end
  end
end
