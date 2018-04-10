defmodule Storm.State.StateServer do
  use GenServer

  alias Storm.Simulation
  alias Storm.Session
  alias Storm.State

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init([simulation_id, supervisor]) do
    simulation = %Db.Simulation{} = Db.Simulation.get(simulation_id)
    state = %State{
      simulation: simulation,
      sessions: group_sessions(simulation.sessions),
      supervisor: supervisor
    }

    {:ok, state}
  end

  def handle_call(:get_simulation_state, _, state) do
    {:reply, simulation_state(state), state}
  end
  def handle_call({:get_session_state, id}, _, state) do
    session = session_state(state.simulation, Map.get(state.sessions, id))

    {:reply, session, state}
  end

  defp group_sessions(sessions) do
    sessions
    |> Enum.group_by(&(&1.id))
    |> Enum.map(fn {id, [session]} -> {id, session} end)
    |> Enum.into(%{})
  end

  defp simulation_state(%{simulation: simulation, supervisor: supervisor}) do
    %Simulation{
      id: simulation.id,
      supervisor: supervisor,
      duration: simulation.duration,
      protocol_mod: simulation.protocol_mod,
      transport_mod: simulation.transport_mod,
      clients_started: simulation.clients_started,
      sessions: Enum.map(simulation.sessions, &session_state(simulation, &1))
    }
  end

  defp session_state(simulation, session) do
    %Session{
      id: session.id,
      simulation_id: simulation.id,
      clients: session.clients,
      arrival_rate: session.arrival_rate,
      clients_started: session.clients_started,
      scenario: session.scenario
    }
  end
end
