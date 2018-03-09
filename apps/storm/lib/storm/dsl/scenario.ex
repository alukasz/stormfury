defmodule Storm.DSL.Scenario do
  alias Storm.DSL.Util

  def build(ast) do
    try do
      scenario = ast
      |> transform_expr(%{})
      |> List.flatten()

      {:ok, scenario}
    rescue
      e in RuntimeError -> {:error, e.message}
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
  defp transform_expr({form, args}, _) do
    raise "invalid expression #{form} with arguments #{inspect args}"
  end
end
