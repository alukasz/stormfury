defmodule Db.SessionTest do
  use Db.MnesiaCase

  alias Db.Repo
  alias Db.Session

  describe "get/1" do
    test "returns Session" do
      Repo.insert(%Session{id: 42})

      assert %Session{id: 42} = Session.get(42)
    end

    test "returns nil when Session not found" do
      refute Session.get(42)
    end
  end

  describe "insert/1" do
    test "inserts session" do
      assert :ok = Session.insert(%Session{id: 42})

      assert %Session{id: 42} = Repo.get(Session, 42)
    end
  end

  describe "update/2" do
    test "updates session" do
      Repo.insert(%Session{id: 42})

      assert %Session{id: 42, clients_started: 10} =
        Session.update(%Session{id: 42}, clients_started: 10)

      assert %Session{id: 42, clients_started: 10} = Repo.get(Session, 42)
    end

    test "updates session by id" do
      Repo.insert(%Session{id: 42})

      assert %Session{id: 42, clients_started: 10} =
        Session.update(42, clients_started: 10)

      assert %Session{id: 42, clients_started: 10} = Repo.get(Session, 42)
    end

    test "returns error tuple when record does not exist" do
      assert {:error, :not_found} =
        Session.update(%Session{id: 42}, clients_started: 10)
    end
  end

  describe "get_by_simulation_id/1" do
    test "returns all sessions for given simulation id" do
      Repo.insert(%Session{id: 1, simulation_id: 42})
      Repo.insert(%Session{id: 2, simulation_id: 2})
      Repo.insert(%Session{id: 3, simulation_id: 42})
      Repo.insert(%Session{id: 4, simulation_id: 4})

      sessions = Session.get_by_simulation_id(42)

      assert sessions |> Enum.map(&(&1.id)) |> Enum.sort() == [1, 3]
    end

    test "returns empty list when no session matches" do
      Repo.insert(%Session{id: 1, simulation_id: 4})
      Repo.insert(%Session{id: 2, simulation_id: 2})

      assert Session.get_by_simulation_id(42) == []
    end
  end
end
