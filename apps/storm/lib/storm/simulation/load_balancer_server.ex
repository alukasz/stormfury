defmodule Storm.Simulation.LoadBalancerServer do
  use GenServer

  alias Storm.Simulation

  @fury_bridge Application.get_env(:storm, :fury_bridge)
  @registry Storm.LoadBalancer.Registry

  defmodule State do
    defstruct nodes: [], to_start: %{}
  end

  def start_link(%Simulation{id: id, nodes: nodes}) do
    GenServer.start_link(__MODULE__, nodes, name: name(id))
  end

  def name(id) do
    {:via, Registry, {@registry, id}}
  end

  def init(nodes) do
    {:ok, %State{nodes: nodes}}
  end

  def handle_call({:start_clients, session_id, ids}, _, state) do
    to_start = Map.update(state.to_start, session_id, [ids], &(&1 ++ [ids]))

    {:reply, :ok, %{state | to_start: to_start}}
  end

  def handle_info(:do_start_clients, state) do
    %{nodes: nodes, to_start: to_start} = state
    {now, next_time} = split_by_start_time(to_start)
    clients_per_node = calculate_clients_per_node(nodes, now)

    now
    |> split_clients_between_nodes(nodes, clients_per_node)
    |> start_clients()

    {:noreply, %{state | to_start: next_time}}
  end


  defp split_by_start_time(to_start) do
    now = Enum.map to_start, fn {session, [h | _]} -> {session, h} end
    next_time =
      to_start
      |> Enum.map(fn {session, [_ | t]} -> {session, t} end)
      |> Enum.filter(fn
        {_, []} -> false
        _ -> true
      end)
      |> Enum.into(%{})

    {now, next_time}
  end

  defp calculate_clients_per_node(nodes, to_start) do
    to_start
    |> Enum.reduce(0, fn {_, ids}, acc ->
        acc + Enum.count(ids)
      end)
    |> Kernel./(length(nodes))
    |> Float.ceil()
    |> round()
  end

  defp split_clients_between_nodes([], _, _), do: []
  defp split_clients_between_nodes(clients, nodes, per_node) do
    clients =
      clients
      |> zip_session_with_client()
      |> Enum.shuffle()
      |> Enum.chunk_every(per_node)
      |> Enum.map(&group_by_session_and_unzip/1)

    Enum.zip(nodes, clients)
  end

  defp zip_session_with_client(clients) do
    Enum.reduce clients, [], fn {session, clients}, acc ->
      session
      |> List.wrap()
      |> Stream.cycle()
      |> Enum.zip(clients)
      |> Enum.concat(acc)
    end
  end

  defp group_by_session_and_unzip(clients) do
    clients
    |> Enum.group_by(&elem(&1, 0))
    |> Enum.map(fn {session, clients} ->
      {session, Keyword.values(clients)}
    end)
  end

  defp start_clients(to_fury) do
    Enum.each to_fury, fn {node, sessions}->
      Enum.each sessions, fn {session, clients} ->
        @fury_bridge.start_clients(node, session, clients)
      end
    end
  end
end
