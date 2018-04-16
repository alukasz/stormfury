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

  describe "increasing counters" do
    setup %{ref: ref} do
      for _ <- 1..2, do: Metrics.incr(ref, :id, :clients)
      for _ <- 1..3, do: Metrics.incr(ref, :id, :clients_connected)
      for _ <- 1..4, do: Metrics.incr(ref, :id, :messages_sent)
      for _ <- 1..5, do: Metrics.incr(ref, :id, :messages_received)

      :ok
    end

    test "counters are updated", %{ref: ref} do
      metrics = Metrics.get(ref)

      assert {:clients, 2} in metrics
      assert {:clients_connected, 3} in metrics
      assert {:messages_sent, 4} in metrics
      assert {:messages_received, 5} in metrics
    end
  end

  describe "decreasing counters" do
    setup %{ref: ref} do
      for _ <- 1..2, do: Metrics.decr(ref, :id, :clients)
      for _ <- 1..3, do: Metrics.decr(ref, :id, :clients_connected)
      for _ <- 1..4, do: Metrics.decr(ref, :id, :messages_sent)
      for _ <- 1..5, do: Metrics.decr(ref, :id, :messages_received)

      :ok
    end

    test "counters are updated", %{ref: ref} do
      metrics = Metrics.get(ref)

      assert {:clients, -2} in metrics
      assert {:clients_connected, -3} in metrics
      assert {:messages_sent, -4} in metrics
      assert {:messages_received, -5} in metrics
    end
  end
end
