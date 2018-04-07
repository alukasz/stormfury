defmodule Storm.DispatcherTest do
  use ExUnit.Case, async: true

  alias Storm.Dispatcher
  alias Storm.Dispatcher.DispatcherServer

  describe "start_clients/3" do
    setup do
      simulation_id = make_ref()
      {:ok, _} = start_supervised({DispatcherServer, simulation_id})

      {:ok, simulation_id: simulation_id}
    end

    test "replies :ok", %{simulation_id: id} do
      assert Dispatcher.start_clients(id, :session, 1..10) == :ok
    end
  end

  describe "name/1" do
    test "returns :via tuple for name registration" do
      assert Dispatcher.name(:id) ==
        {:via, Registry, {Storm.Registry.Dispatcher, :id}}
    end
  end
end
