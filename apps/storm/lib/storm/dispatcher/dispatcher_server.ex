defmodule Storm.Dispatcher.DispatcherServer do
  use GenServer

  alias Storm.Dispatcher

  @fury_bridge Application.get_env(:storm, :fury_bridge)

  defmodule State do
    defstruct [
      :simulation_id,
      to_start: []
    ]
  end

  def start_link(simulation_id) do
    GenServer.start_link(__MODULE__, simulation_id, name: name(simulation_id))
  end

  def init(simulation_id) do
    schedule_start_clients()

    {:ok, %State{simulation_id: simulation_id}}
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
    %{simulation_id: simulation_id, to_start: clients} = state

    simulation_id
    |> Fury.group()
    |> :pg2.get_members()
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

  defp name(id) do
    Dispatcher.name(id)
  end
end
