defmodule Storm.DSL.AST do
  alias Storm.DSL.Lexer
  alias Storm.DSL.Parser

  def build(dsl) do
    with {:ok, tokens} <- Lexer.tokenize(dsl),
         {:ok, ast} <- Parser.parse(tokens) do
      ast
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
end
