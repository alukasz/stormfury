defmodule Db.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    :mnesia.start()

    Supervisor.start_link([], strategy: :one_for_one, name: Db.Supervisor)
  end
end
