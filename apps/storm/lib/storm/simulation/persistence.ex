defmodule Storm.Simulation.Persistence do
  alias Storm.Simulation
  alias Storm.Session

  def get_simulation(simulation_id) do
    simulation_id
    |> Db.Simulation.get()
    |> translate_simulation()
  end

  def update_simulation(simulation_id, attrs) do
    %Db.Simulation{} = Db.Simulation.update(simulation_id, attrs)
  end

  def update_session(session_id, attrs) do
    %Db.Session{} = Db.Session.update(session_id, attrs)
  end

  defp translate_simulation(%Db.Simulation{} = simulation) do
    %Simulation{
      id: simulation.id,
      duration: simulation.duration,
      protocol_mod: simulation.protocol_mod,
      transport_mod: simulation.transport_mod,
      clients_started: simulation.clients_started,
      sessions: Enum.map(
        simulation.sessions,
        &translate_session(simulation.id, &1)
      ),
    }
  end

  defp translate_session(simulation_id, %Db.Session{} = session) do
    %Session{
      id: session.id,
      simulation_id: simulation_id,
      clients: session.clients,
      arrival_rate: session.arrival_rate,
      clients_started: session.clients_started,
      scenario: session.scenario,
    }
  end
end
