defmodule Storm.State do
  alias Storm.State.StateServer

  defstruct [
    :simulation,
    :supervisor,
    sessions: %{}
  ]

  defdelegate start_link(opts), to: StateServer

  def simulation(pid) do
    GenServer.call(pid, :get_simulation_state)
  end

  def session(pid, session_id) do
    GenServer.call(pid, {:get_session_state, session_id})
  end
end
