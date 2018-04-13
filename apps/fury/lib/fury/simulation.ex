defmodule Fury.Simulation do
  alias Fury.Simulation
  alias Fury.Simulation.SimulationsSupervisor

  def start(simulation_id, sessions) do
    SimulationsSupervisor.start_child(simulation_id, sessions)
  end

  def terminate(simulation_sup_pid) do
    SimulationsSupervisor.terminate_child(simulation_sup_pid)
  end
end
