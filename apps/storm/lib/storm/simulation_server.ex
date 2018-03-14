defmodule Storm.SimulationServer do
  use GenServer

  alias Storm.Session

  def start_link(%{id: id} = state) do
    GenServer.start_link(__MODULE__, state, name: name(id))
  end

  def get_node(id) do
    GenServer.call(name(id), :get_node)
  end

  def init(state) do
    send(self(), :start_sessions)

    {:ok, state}
  end

  def handle_info(:start_sessions, %{sessions: sessions} = state) do
    Enum.each(sessions, &Session.new(&1))

    {:noreply, state}
  end

  def handle_call(:get_node, _, %{nodes: nodes} = state) do
    {:reply, {:ok, Enum.random(nodes)}, state}
  end

  defp name(id) do
    {:via, Registry, {Storm.Simulation.Registry, id}}
  end
end
