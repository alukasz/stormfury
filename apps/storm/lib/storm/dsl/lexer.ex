defmodule Storm.DSL.Lexer do
  @lexer :storm_dsl_lexer

  def tokenize(dsl) when is_binary(dsl) do
    dsl
    |> to_charlist()
    |> @lexer.string()
    |> case do
         {:ok, tokens, _} -> {:ok, tokens}
         error -> tranform_error(error)
       end
  end

  defp tranform_error({:error, {line, _, {:illegal, token}}, _}) do
    {:error, {"illegal character: '#{token}'", line}}
  end
end
