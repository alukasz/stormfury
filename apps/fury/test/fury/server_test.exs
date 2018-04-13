defmodule Fury.ServerTest do
  use ExUnit.Case, async: true

  alias Fury.Server

  setup do
    {:ok, id: make_ref()}
  end

  describe "handle_call {:start_simulation, simulation}" do
    test "starts simulation", %{id: id} do
      {:reply, {:ok, _}, _} =
        Server.handle_call({:start_simulation, id, []}, :from, %{})
    end

    test "creates pg2 group", %{id: id} do
      Server.handle_call({:start_simulation, id, []}, :from, %{})

      assert Fury.group(id) in :pg2.which_groups()
    end
  end
end
