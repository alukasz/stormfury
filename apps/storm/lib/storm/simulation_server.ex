defmodule Storm.SimulationServer do
  use GenServer

  alias Storm.Session

  @fury_bridge Application.get_env(:storm, :fury_bridge)
  @nodes Application.get_env(:storm, :nodes)

  defmodule State do
    defstruct simulation: nil, clients_started: 0, nodes: []
  end

  def start_link(%Db.Simulation{id: id} = simulation) do
    GenServer.start_link(__MODULE__, simulation, name: name(id))
  end

  def name(id) do
    {:via, Registry, {Storm.Simulation.Registry, id}}
  end

  def init(simulation) do
    send(self(), :start_slaves)

    {:ok, %State{simulation: simulation}}
  end

  def handle_call({:get_ids, number}, _, %{clients_started: started} = state) do
    new_started = started + number
    range = (started + 1)..new_started

    {:reply, range, %{state | clients_started: new_started}}
  end

  def handle_info(:start_slaves, %{simulation: %{hosts: hosts}} = state) do
    nodes = for host <- hosts do
      {:ok, node} = @nodes.start_node(host)
      :mnesia.change_config(:extra_db_nodes, [node])

      node
    end
    send(self(), :start_sessions)

    {:noreply, %{state | nodes: nodes}}
  end

  def handle_info(:start_sessions, %{simulation: simulation} = state) do
    %{nodes: nodes} = state
    %{id: simulation_id, sessions: sessions} = simulation

    Enum.each nodes, fn node ->
      @fury_bridge.start_sessions(node, simulation_id)
    end
    Enum.map(sessions, &Session.new(&1))

    {:noreply, state}
  end
end
