defmodule Storm.DSL do
  alias Storm.DSL.AST
  alias Storm.DSL.Scenario

  def parse(dsl) do
    with {:ok, ast} <- AST.build(dsl),
         {:ok, scenario} <- Scenario.build(ast) do
      {:ok, scenario}
    else
      error -> error
    end
  end
end
