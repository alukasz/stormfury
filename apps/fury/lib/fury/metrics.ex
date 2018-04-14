defmodule Fury.Metrics do
  def new do
    :ets.new(:fury_metrics, [:set, :public, write_concurrency: true,
                             read_concurrency: true])
  end

  def incr(ref, kind) do
    :ets.update_counter(ref, kind, 1, {1, 0})
  end

  def decr(ref, kind) do
    :ets.update_counter(ref, kind, -1, {1, 0})
  end

  def get(ref) do
    ref
    |> :ets.match(:"$1")
    |> List.flatten()
  end
end
