defmodule Fury.Session.CacheTest do
  use ExUnit.Case, async: true

  alias Fury.Session.Cache

  describe "new/1" do
    test "creates new cache storage" do
      assert Cache.new(__MODULE__)
    end
  end

  describe "get/2" do
    setup :create_cache

    test "retrieves element from cache", %{cache: cache} do
      :ets.insert(cache, {10, :data})

      assert Cache.get(cache, 10) == {:ok, :data}
    end

    test "returns error tuple when element not exist", %{cache: cache} do
      assert Cache.get(cache, 10) == :error
    end
  end

  describe "put/3" do
    setup :create_cache

    test "inserts new element to cache", %{cache: cache} do
      Cache.put(cache, 10, :data)

      assert :ets.lookup(cache, 10) == [{10, :data}]
    end

    test "multiple calls overwrite cache", %{cache: cache} do
      Cache.put(cache, 10, :data)
      Cache.put(cache, 10, :updated_data)

      assert :ets.lookup(cache, 10) == [{10, :updated_data}]
    end
  end

  defp create_cache(%{line: line}) do
    cache = Cache.new(:"cache_test_#{line}")

    {:ok, cache: cache}
  end
end
