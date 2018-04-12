defmodule Db.SimulationsTest do
  use Db.MnesiaCase

  alias Db.Repo
  alias Db.Simulation
  alias Db.Session

  describe "get/1" do
    test "returns simulation by id" do
      Repo.insert(%Simulation{id: 42})

      assert %Simulation{id: 42, sessions: []} = Simulation.get(42)
    end

    test "returns sessions of simulation" do
      Repo.insert(%Simulation{id: 42})
      Repo.insert(%Session{id: 11, simulation_id: 42})
      Repo.insert(%Session{id: 12, simulation_id: 1})
      Repo.insert(%Session{id: 13, simulation_id: 42})

      assert %{sessions: sessions} = Simulation.get(42)


      assert sessions |> Enum.map(&(&1.id)) |> Enum.sort() == [11, 13]
    end

    test "returns null when simulation does not exist" do
      assert Simulation.get(42) == nil
    end
  end

  describe "insert/1" do
    test "inserts simulation" do
      assert :ok = Simulation.insert(%Simulation{id: 42})

      assert %Simulation{id: 42} = Repo.get(Simulation, 42)
    end

    test "inserts sessions of simulation" do
      sessions = [%Session{id: 11}, %Session{id: 12}]
      simulation = %Simulation{id: 42, sessions: sessions}

      assert :ok = Simulation.insert(simulation)

      assert %Session{id: 11} = Repo.get(Session, 11)
      assert %Session{id: 12} = Repo.get(Session, 12)
    end

    test "does not store sessions in simulations table" do
      simulation = %Simulation{id: 42, sessions: [%Session{id: 11}]}

      Simulation.insert(simulation)

      assert %{sessions: []} = Repo.get(Simulation, 42)
    end

    test "rollbacks transaction on error" do
      simulation = %Simulation{id: 42, sessions: [id: 11]}

      {:error, _} = Simulation.insert(simulation)

      refute Repo.get(Simulation, 42)
      refute Repo.get(Session, 11)
    end

    test "does not store Simulation on error" do
      simulation =
        %Simulation{id: 42, sessions: [id: 11]}
        |> Map.put(:invalid_key, nil)

      assert {:error, _} = Simulation.insert(simulation)
    end
  end

  describe "update/2" do
    test "updates simulation" do
      Repo.insert(%Simulation{id: 42})

      assert %Simulation{id: 42, clients_started: 10} =
        Simulation.update(%Simulation{id: 42}, clients_started: 10)

      assert %Simulation{id: 42, clients_started: 10} = Repo.get(Simulation, 42)
    end

    test "updates simulation by id" do
      Repo.insert(%Simulation{id: 42})

      assert %Simulation{id: 42, clients_started: 10} =
        Simulation.update(42, clients_started: 10)

      assert %Simulation{id: 42, clients_started: 10} = Repo.get(Simulation, 42)
    end

    test "returns error tuple when record does not exist" do
      assert {:error, :not_found} =
        Simulation.update(%Simulation{id: 42}, clients_started: 10)
    end
  end
end
