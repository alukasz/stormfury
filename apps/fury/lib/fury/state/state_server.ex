defmodule Fury.State.StateServer do
  use GenServer

  alias Fury.State

  def start_link(simulation_id) do
    GenServer.start_link(__MODULE__, [], name: name(simulation_id))
  end

  def init(_) do
    {:ok, %{}}
  end

  def handle_call({:get_ids, session_id}, _, state) do
    {:reply, Map.get(state, session_id, []), state}
  end

  def handle_cast({:add_ids, session_id, ids}, state) do
    state = Map.update state, session_id, ids, fn old_ids ->
      Enum.uniq(ids ++ old_ids)
    end

    {:noreply, state}
  end

  defp name(id) do
    State.name(id)
  end
end
