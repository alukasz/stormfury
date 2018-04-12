defmodule Storm.Simulation.Persistence do
  alias Storm.Simulation
  alias Storm.Session

  def get_simulation(simulation_id) do
    simulation_id
    |> Db.Simulation.get()
    |> translate_simulation()
  end

  def get_session(session_id, simulation_id) do
    session_id
    |> Db.Session.get()
    |> translate_session(simulation_id)
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
      url: simulation.url,
      duration: simulation.duration,
      protocol_mod: simulation.protocol_mod,
      transport_mod: simulation.transport_mod,
      clients_started: simulation.clients_started,
      state: simulation.state,
      sessions: Enum.map(
        simulation.sessions,
        &translate_session(&1, simulation.id)
      ),
    }
  end

  defp translate_session(%Db.Session{} = session, simulation_id) do
    %Session{
      id: session.id,
      simulation_id: simulation_id,
      clients: session.clients,
      arrival_rate: session.arrival_rate,
      clients_started: session.clients_started,
      scenario: session.scenario,
      state: session.state,
    }
  end
end
