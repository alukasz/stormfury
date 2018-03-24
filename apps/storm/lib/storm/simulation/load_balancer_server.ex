defmodule Storm.Simulation.LoadBalancerServer do
  use GenServer

  @fury_bridge Application.get_env(:storm, :fury_bridge)
  @registry Storm.LoadBalancer.Registry

  defmodule State do
    defstruct nodes: [], to_start: []
  end

  def start_link(%Db.Simulation{id: id, hosts: hosts}) do
    GenServer.start_link(__MODULE__, hosts, name: name(id))
  end

  def name(id) do
    {:via, Registry, {@registry, id}}
  end

  def init(hosts) do
    schedule_start_clients()
    nodes = Enum.map(hosts, &(:"fury@#{&1}"))

    {:ok, %State{nodes: nodes}}
  end

  def handle_call({:add_clients, clients}, _, state) do
    to_start = Enum.concat(state.to_start, clients)

    {:reply, :ok, %{state | to_start: to_start}}
  end

  def handle_info(:start_clients, %{to_start: []} = state) do
    schedule_start_clients()

    {:noreply, state}
  end
  def handle_info(:start_clients, state) do
    schedule_start_clients()
    %{nodes: nodes, to_start: clients} = state

    nodes
    |> zip_with_clients(clients)
    |> group_by_node()
    |> group_by_sessions()
    |> do_start_clients()

    {:noreply, %{state | to_start: []}}
  end

  defp zip_with_clients(nodes, clients) do
    nodes
    |> Enum.shuffle()
    |> Stream.cycle()
    |> Enum.zip(clients)
    |> Enum.shuffle()
  end

  defp group_by_node(clients) do
    Enum.group_by(clients, &elem(&1, 0), &elem(&1, 1))
  end

  defp group_by_sessions(nodes) do
    Enum.map nodes, fn {node, clients} ->
      sessions = Enum.group_by(clients, &elem(&1, 0), &elem(&1, 1))
      {node, sessions}
    end
  end

  defp do_start_clients(nodes) do
    Enum.each nodes, fn {node, sessions} ->
      Enum.each sessions, fn {session, clients} ->
        @fury_bridge.start_clients(node, session, clients)
      end
    end
  end

  defp schedule_start_clients do
    Process.send_after(self(), :start_clients, :timer.seconds(1))
  end
end
