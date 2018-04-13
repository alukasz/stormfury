defmodule Fury.Cache do
  def new(name) when is_atom(name) do
    opts = [:set, :private, read_concurrency: true]

    :ets.new(name, opts)
  end

  def get(table, id) do
    case :ets.lookup(table, id) do
      [{_, result}| _] -> {:ok, result}
      [] -> :error
    end
  end

  def put(table, id, data) do
    :ets.insert(table, {id, data})
  end
end
