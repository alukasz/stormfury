defmodule Fury.DSL.AST do
  alias Fury.DSL.Lexer
  alias Fury.DSL.Parser

  def build(dsl) do
    with {:ok, tokens} <- Lexer.tokenize(dsl) do
      Parser.parse(tokens)
    else
      error -> error
    end
  end

  def traverse(ast, acc \\ %{}, fun) do
    do_traverse(ast, acc, fun)
  end

  defp do_traverse(list, acc, fun) when is_list(list) do
    Enum.reduce list, acc, fn x, acc ->
      do_traverse(x, acc, fun)
    end
  end
  defp do_traverse({_, args} = ast, acc, fun) do
    acc = fun.(ast, acc)
    do_traverse(args, acc, fun)
  end
  defp do_traverse(_, acc, _), do: acc

  def transform(list, fun) when is_list(list) do
    Enum.map(list, &transform(&1, fun))
  end
  def transform({_, _} = ast, fun) do
    {form, args} = fun.(ast)
    args = transform(args, fun)
    {form, args}
  end
  def transform(ast, _), do: ast
end
