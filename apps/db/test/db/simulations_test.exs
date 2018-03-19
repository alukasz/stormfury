defmodule Db.SimulationsTest do
  use Db.MnesiaCase

  alias Db.Simulations
  alias Db.Repo
  alias Storm.Simulation
  alias Storm.Session

  describe "get/1" do
    test "returns simulation by id" do
      Repo.insert(%Simulation{id: 42})

      assert %Simulation{id: 42, sessions: []} = Simulations.get(42)
    end

    test "returns sessions of simulation" do
      Repo.insert(%Simulation{id: 42})
      Repo.insert(%Session{id: 11, simulation_id: 42})
      Repo.insert(%Session{id: 12, simulation_id: 1})
      Repo.insert(%Session{id: 13, simulation_id: 42})

      assert %{sessions: sessions} = Simulations.get(42)

      assert sessions |> Enum.map(&(&1.id)) |> Enum.sort() == [11, 13]
    end

    test "returns null when simulation does not exist" do
      assert Simulations.get(42) == nil
    end
  end

  describe "insert/1" do
    test "inserts simulation" do
      assert :ok = Simulations.insert(%Simulation{id: 42})

      assert %Simulation{id: 42} = Repo.get(Simulation, 42)
    end

    test "inserts sessions of simulation" do
      sessions = [%Session{id: 11}, %Session{id: 12}]
      simulation = %Simulation{id: 42, sessions: sessions}

      assert :ok = Simulations.insert(simulation)

      assert %Session{id: 11} = Repo.get(Session, 11)
      assert %Session{id: 12} = Repo.get(Session, 12)
    end

    test "does not store sessions in simulations table" do
      simulation = %Simulation{id: 42, sessions: [%Session{id: 11}]}

      Simulations.insert(simulation)

      assert %{sessions: []} = Repo.get(Simulation, 42)
    end

    test "rollbacks transaction on error" do
      simulation = %Simulation{id: 42, sessions: [id: 11]}

      {:error, "not a session" <> _} = Simulations.insert(simulation)

      refute Repo.get(Simulation, 42)
      refute Repo.get(Session, 12)
    end
  end
end
