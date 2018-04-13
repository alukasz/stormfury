defmodule Fury.DSL.Parser do
  @parser :fury_dsl_parser

  def parse([]) do
    {:error, :no_tokens}
  end
  def parse(tokens) do
    case @parser.parse(tokens) do
      {:ok, ast} ->
        {:ok, ast}

      {:error, {line, _, [msg, args]}} ->
        {:error, {to_string(msg) <> to_string(args), line}}
    end
  end
end
