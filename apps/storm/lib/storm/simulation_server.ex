defmodule Storm.SimulationServer do
  use GenServer

  alias Storm.Session

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

  def handle_call(:get_node, _, %{simulation: %{nodes: nodes}} = state) do
    {:reply, {:ok, Enum.random(nodes)}, state}
  end
  def handle_call({:get_ids, number}, _, %{clients_started: started} = state) do
    new_started = started + number
    range = (started + 1)..new_started

    {:reply, range, %{state | clients_started: new_started}}
  end

  def handle_info(:start_sessions, state) do
    Enum.each(state.simulation.sessions, &Session.new(&1))

    {:noreply, state}
  end

end
