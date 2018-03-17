defmodule Storm.SimulationServer do
  use GenServer

  alias Storm.Session

  @fury_bridge Application.get_env(:storm, :fury_bridge)

  defmodule State do
    defstruct simulation: nil, clients_started: 0
  end

  def start_link(%{id: id} = simulation) do
    GenServer.start_link(__MODULE__, simulation, name: name(id))
  end

  def name(id) do
    {:via, Registry, {Storm.Simulation.Registry, id}}
  end

  def init(simulation) do
    send(self(), :start_sessions)

    {:ok, %State{simulation: simulation}}
  end

  def handle_call({:get_ids, number}, _, %{clients_started: started} = state) do
    new_started = started + number
    range = (started + 1)..new_started

    {:reply, range, %{state | clients_started: new_started}}
  end

  def handle_info(:start_sessions, %{simulation: simulation} = state) do
    %{nodes: nodes, sessions: sessions, protocol_mod: protocol_mod,
      transport_mod: transport_mod, url: url} = simulation

    Enum.each(nodes, fn node ->
      Enum.each(sessions, fn %{id: session_id} ->
        opts = [session_id, url, transport_mod, protocol_mod]
        {:ok, _} = @fury_bridge.start_session(node, opts)
      end)
    end)
    Enum.each(sessions, &Session.new(&1))

    {:noreply, state}
  end

end
