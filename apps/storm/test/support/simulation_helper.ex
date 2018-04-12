defmodule Storm.SimulationHelper do
  import ExUnit.Callbacks

  alias Storm.Session
  alias Storm.Simulation
  alias Storm.Simulation.SimulationServer

  def default_simulation(_) do
    simulation = %Simulation{
      id: make_ref(),
      duration: 0,
    }

    {:ok, simulation: simulation}
  end

  def default_session(%{simulation: %{id: id} = simulation}) do
    session = %Session{
      id: make_ref(),
      simulation_id: id,
      clients: 10,
      arrival_rate: 2
    }
    simulation = %{simulation | sessions: [session]}

    {:ok, simulation: simulation, session: session}
  end

  def insert_simulation(simulation, attrs \\ [])
  def insert_simulation(%{simulation: simulation}, attrs) do
    insert_simulation(simulation, attrs)
  end
  def insert_simulation(simulation, attrs) do
    simulation
    |> translate_simulation()
    |> Map.merge(Enum.into(attrs, %{}))
    |> Db.Simulation.insert()
  end

  def start_simulation_server(%{simulation: %{id: id}}) do
    {:ok, _} = start_supervised({SimulationServer, [id, self()]})

    :ok
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
