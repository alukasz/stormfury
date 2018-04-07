defmodule Storm.Simulation.SimulationServer do
  use GenServer

  @fury_bridge Application.get_env(:storm, :fury_bridge)

  defmodule State do
    defstruct [
      simulation: nil,
      clients_started: 0,
      nodes: []
    ]
  end

  def start_link(%Db.Simulation{id: id} = simulation) do
    GenServer.start_link(__MODULE__, simulation, name: name(id))
  end

  def name(id) do
    {:via, Registry, {Storm.Simulation.Registry, id}}
  end

  def init(simulation) do
    {:ok, %State{simulation: simulation}}
  end

  def handle_call({:get_ids, number}, _, %{clients_started: started} = state) do
    new_started = started + number
    range = (started + 1)..new_started

    {:reply, range, %{state | clients_started: new_started}}
  end
end
