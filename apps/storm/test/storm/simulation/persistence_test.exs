defmodule Storm.Simulation.PersistenceTest do
  use ExUnit.Case, async: true

  import Storm.SimulationHelper

  alias Storm.Simulation.Persistence

  setup :default_simulation
  setup :default_session
  setup :insert_simulation

  describe "get_simulation/1" do
    test "returns %Simulation{} based on data in Db",
        %{simulation: simulation} do
      assert simulation == Persistence.get_simulation(simulation.id)
    end
  end

  describe "update_simulation/2" do
    test "updates simulation in Db", %{simulation: %{id: id}} do
      Persistence.update_simulation(id, clients_started: 100)

      assert %{clients_started: 100} = Db.Simulation.get(id)
    end
  end

  describe "update_session/2" do
    test "updates session in Db", %{session: %{id: id}} do
      Persistence.update_session(id, clients_started: 50)

      assert %{clients_started: 50} = Db.Session.get(id)
    end
  end
end
