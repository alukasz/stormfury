defmodule Fury.MetricsTest do
  use ExUnit.Case, async: true

  alias Fury.Metrics

  setup do
    {:ok, ref: Metrics.new()}
  end

  describe "new/0" do
    test "returns ref to ETS table" do
      ref = Metrics.new()

      assert is_reference(ref)
    end
  end

  describe "incr/2" do
    test "increases counter by 1", %{ref: ref} do
      assert Metrics.incr(ref, :counter) == 1

      assert :ets.lookup(ref, :counter) == [counter: 1]
    end
  end

  describe "decr/2" do
    test "returns ref to ETS table", %{ref: ref} do
      assert Metrics.decr(ref, :counter) == -1

      assert :ets.lookup(ref, :counter) == [counter: -1]
    end
  end

  describe "get/1" do
    setup %{ref: ref} do
      for _ <- 1..5, do: Metrics.incr(ref, :a)
      for _ <- 1..10, do: Metrics.incr(ref, :b)

      :ok
    end

    test "returns all keys with values", %{ref: ref} do
      assert Enum.sort(Metrics.get(ref)) == [a: 5, b: 10]
    end
  end
end
