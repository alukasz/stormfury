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

    case get_remote_pids(simulation_id) do
      [] ->
        {:noreply, state}

      pids ->
        do_start_clients(pids, clients)

        {:noreply, %{state | to_start: []}}
    end
  end

  defp do_start_clients(pids, clients) do
    pids
    |> zip_with_clients(clients)
    |> group_by_pid()
    |> group_by_sessions()
    |> call_remote_simulations()
  end

  defp get_remote_pids(simulation_id) do
    simulation_id
    |> Fury.group()
    |> :pg2.get_members()
  end

  defp zip_with_clients([], _) do
    []
  end
  defp zip_with_clients(pids, clients) do
    pids
    |> Enum.shuffle()
    |> Stream.cycle()
    |> Enum.zip(clients)
    |> Enum.shuffle()
  end

  defp group_by_pid(clients) do
    Enum.group_by(clients, &elem(&1, 0), &elem(&1, 1))
  end

  defp group_by_sessions(pids) do
    Enum.map pids, fn {pid, clients} ->
      sessions = Enum.group_by(clients, &elem(&1, 0), &elem(&1, 1))
      {pid, sessions}
    end
  end

  defp call_remote_simulations(pids) do
    Enum.each pids, fn {pid, sessions} ->
      Enum.each sessions, fn {session, clients} ->
        @fury_bridge.start_clients(pid, session, clients)
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
