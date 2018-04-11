defmodule Storm.State do
  alias Storm.State.StateServer

  defstruct [
    :simulation,
    :supervisor_pid,
    sessions: %{}
  ]

  def simulation(pid) do
    GenServer.call(pid, :get_simulation_state)
  end

  def session(pid, session_id) do
    GenServer.call(pid, {:get_session_state, session_id})
  end

  def update_simulation(pid, attrs) do
    GenServer.cast(pid, {:update_simulation, attrs})
  end

  def update_session(pid, session_id, attrs) do
    GenServer.cast(pid, {:update_session, session_id, attrs})
  end
end
