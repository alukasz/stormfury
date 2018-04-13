defmodule Fury.DSL do
  alias Fury.DSL.AST
  alias Fury.DSL.Scenario

  def parse(dsl) do
    with {:ok, ast} <- AST.build(dsl) do
      Scenario.build(ast)
    else
      error -> error
    end
  end
end
