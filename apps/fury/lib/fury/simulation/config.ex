defmodule Fury.Simulation.Config do
  def simulation(simulation_id) do
    GenServer.call(name(simulation_id), :simulation)
  end

  def session(simulation_id, session_id) do
    GenServer.call(name(simulation_id), {:session, session_id})
  end

  def client(simulation_id) do
    GenServer.call(name(simulation_id), :client)
  end

  def name(simulation_id) do
    {:via, Registry, {Fury.Registry.Config, simulation_id}}
  end
end
