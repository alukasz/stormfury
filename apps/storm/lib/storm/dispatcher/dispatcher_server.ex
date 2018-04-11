defmodule Storm.Dispatcher.DispatcherServer do
  use GenServer

  alias Storm.Dispatcher

  require Logger

  @fury_bridge Application.get_env(:storm, :fury_bridge)

  def start_link([%Dispatcher{}, _] = opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init([simulation_id, simulation_pid, supervisor_pid, sessions]) do
    Logger.metadata(simulation: simulation_id)



    Storm.Launcher.LauncherSupervisor.start_link([sessions, self()])

    schedule_start_clients()

    state = %Dispatcher{
      simulation_id: simulation_id,
      supervisor_pid: supervisor_
    }


    {:ok, }
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
        Logger.warn("No remote simulations running, #{length(clients)} clients to dispatch")
        {:noreply, state}

      pids ->
        do_start_clients(pids, clients)

        {:noreply, %{state | to_start: []}}
    end
  end

  defp do_start_clients(pids, clients) do
    Logger.debug("Dispatching #{length(clients)} clients between #{length(pids)} nodes")

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
