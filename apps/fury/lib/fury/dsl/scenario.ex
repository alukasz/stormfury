defmodule Fury.DSL.Scenario do
  alias Fury.DSL.AST
  alias Fury.DSL.Util

  def build(ast) do
    scenario = ast
    |> encode_data()
    |> transform_expr(%{})
    |> List.flatten()

    {:ok, scenario}
  rescue
    e in RuntimeError -> {:error, e.message}
  end

  defp encode_data(ast) do
    AST.transform ast, fn
      {:push, [data]} when is_list(data) or is_map(data) ->
        {:push, [Poison.encode!(data)]}

      ast ->
        ast
    end
  end

  defp transform_expr(ast, assigns) when is_list(ast) do
    Enum.map(ast, &transform_expr(&1, assigns))
  end
  defp transform_expr({:think, [time]}, _) do
    {:think, time}
  end
  defp transform_expr({:push, [data]}, assigns) do
    {:push, Util.replace_vars(data, assigns)}
  end
  defp transform_expr({:for, [in_expr, block]}, assigns) do
    {var, range} = transform_expr(in_expr, assigns)

    Enum.map range, fn i ->
      transform_expr(block, Map.put(assigns, var, i))
    end
  end
  defp transform_expr({:block, exprs}, assigns) do
    transform_expr(exprs, assigns)
  end
  defp transform_expr({:in, [var, range]}, assigns) do
    {transform_expr(var, assigns), transform_expr(range, assigns)}
  end
  defp transform_expr({:var, [name]}, _) do
    name
  end
  defp transform_expr({:range, [first, last]}, _) do
    first..last
  end
  defp transform_expr({:list, list}, _) do
    list
  end
  defp transform_expr({form, args}, _) do
    raise "invalid expression #{form} with arguments #{inspect args}"
  end
end
