defmodule FuryTest do
  use Db.MnesiaCase

  describe "start_sessions/1" do
    test "starts sessions for simulation" do
      simulation_id = :simulation_id
      session = %Db.Session{id: :session_id, simulation_id: simulation_id}
      simulation = %Db.Simulation{id: simulation_id, sessions: [session]}
      Db.Simulation.insert(simulation)

      assert :ok = Fury.start_sessions(simulation_id)

      assert [_] = Registry.lookup(Fury.Session.Registry, session.id)
    end

    test "returns error tuple when simulation does not exist" do
      assert {:error, _} = Fury.start_sessions(:simulation_id)
    end
  end
end
