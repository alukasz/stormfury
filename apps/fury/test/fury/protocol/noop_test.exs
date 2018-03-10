defmodule Fury.Protocol.NoopTest do
  use ExUnit.Case, async: true

  alias Fury.Protocol.Noop

  test "init/0 returns empty map" do
    assert Noop.init() == %{}
  end

  test "format/3 returns unmodified payload" do
    payload = "data"

    assert Noop.format(payload, %{}) == {:ok, payload}
  end

  test "handle_data/2 returns unmodified session" do
    session = %{}

    assert Noop.handle_data("", session) == {:ok, session}
  end
end
