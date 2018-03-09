defmodule Storm.DSL.Util do
  def replace_vars(data, assigns) when is_binary(data) do
    Enum.reduce assigns, data, fn {var, value}, data ->
      String.replace(data, var_placeholder(var), to_string(value))
    end
  end
  def replace_vars(data, _) do
    data
  end

  defp var_placeholder(var) do
    "{{" <> var <> "}}"
  end
end
