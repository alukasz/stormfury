defmodule Storm.LauncherTest do
  use ExUnit.Case, async: true

  alias Storm.Launcher
  alias Storm.Launcher.LauncherServer

  describe "perform/1" do
    setup do
      id = make_ref()
      {:ok, _} = start_supervised({LauncherServer, [:id, id]})

      {:ok, session_id: id}
    end

    test "replies with :ok", %{session_id: session_id} do
      assert Launcher.perform(session_id) == :ok
    end
  end

  describe "name/1" do
    test "returns :via tuple for name registration" do
      assert Launcher.name(:id) ==
        {:via, Registry, {Storm.Registry.Launcher, :id}}
    end
  end
end
