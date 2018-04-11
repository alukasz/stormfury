defmodule Storm.SimulationHelper do
  import ExUnit.Callbacks

  alias Storm.Simulation
  alias Storm.Session
  alias Storm.State.StateServer

  def default_simulation(_) do
    simulation = %Simulation{id: make_ref()}

    {:ok, simulation: simulation}
  end

  def default_session(%{simulation: %{id: id} = simulation}) do
    session = %Session{
      id: make_ref(),
      simulation_id: id,
    }
    simulation = %{simulation | sessions: [session]}

    {:ok, simulation: simulation, session: session}
  end

  def insert_simulation(%{simulation: simulation}) do
    Db.Simulation.insert(translate_simulation(simulation))
  end

  def start_config_server(%{simulation: simulation} = state) do
    insert_simulation(state)

    {:ok, pid} = start_supervised({StateServer, [simulation.id, self()]})

    {:ok, state_pid: pid}
  end

  defp translate_simulation(%Db.Simulation{} = simulation) do
    simulation
  end
  defp translate_simulation(%Simulation{} = simulation) do
    simulation = struct(Db.Simulation, Map.from_struct(simulation))
    sessions = Enum.map simulation.sessions, fn session ->
      struct(Db.Session, Map.from_struct(session))
    end

    %{simulation | sessions: sessions}
  end
end
