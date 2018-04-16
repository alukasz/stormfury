defmodule Fury.Metrics do
  @counters [
    :clients,
    :clients_connected,
    :messages_sent,
    :messages_received
  ]

  @shards 100

  @default_value List.to_tuple([:id] ++ List.duplicate(0, length(@counters)))

  def new do
    :ets.new(:fury_metrics, [:set, :public, write_concurrency: true])
  end

  @counters
  |> Enum.with_index(2)
  |> Enum.map(fn {counter, index} ->
    def incr(ref, id, unquote(counter)) do
      :ets.update_counter(
        ref,
        :erlang.phash2(id, @shards),
        {unquote(index), 1},
        @default_value
      )
    end

    def decr(ref, id, unquote(counter)) do
      :ets.update_counter(
        ref,
        :erlang.phash2(id, @shards),
        {unquote(index), -1},
        @default_value
      )
    end
  end)

  defp do_incr(ref, id, pos) do
  end

  defp do_decr(ref, id, pos) do
    :ets.update_counter(ref, id, {pos, -1}, @default_value)
  end

  def get(ref) do
    ref
    |> :ets.match_object(:"$1")
    |> sum_counters(0, 0, 0, 0)
  end

  defp sum_counters([], a1, a2, a3, a4), do: format_counters([a1, a2, a3, a4])
  defp sum_counters([{_, c1, c2, c3, c4} | t], a1, a2, a3, a4) do
    sum_counters(t, a1 + c1, a2 + c2, a3 + c3, a4 + c4)
  end

  defp format_counters(counters) do
    Enum.zip(@counters, counters)
  end
end
