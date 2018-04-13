defmodule Fury.State do
  def add_ids(simulation_id, session_id, ids) do
    GenServer.cast(name(simulation_id), {:add_ids, session_id, ids})
  end

  def get_ids(simulation_id, session_id) do
    GenServer.call(name(simulation_id), {:get_ids, session_id})
  end

  def name(id) do
    {:via, Registry, {Fury.Registry.State, id}}
  end
end
