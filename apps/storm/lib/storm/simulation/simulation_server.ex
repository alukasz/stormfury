defmodule Storm.Simulation.SimulationServer do
  use GenServer

  alias Storm.Simulation
  alias Storm.Launcher

  @fury_bridge Application.get_env(:storm, :fury_bridge)

  defmodule State do
    defstruct [
      simulation: nil,
      clients_started: 0,
    ]
  end

  def start_link(%Db.Simulation{id: id} = simulation) do
    GenServer.start_link(__MODULE__, simulation, name: name(id))
  end

  def init(simulation) do
    Process.send_after(self(), :initialize, 50)

    {:ok, %State{simulation: simulation}}
  end

  def handle_call({:get_ids, number}, _, %{clients_started: started} = state) do
    new_started = started + number
    range = (started + 1)..new_started

    {:reply, range, %{state | clients_started: new_started}}
  end

  def handle_info(:initialize, %{simulation: simulation} = state) do
    create_group(simulation)
    start_remote_simulations(simulation)
    send(self(), :perform)

    {:noreply, state}
  end
  def handle_info(:perform, %{simulation: simulation} = state) do
    timeout = :timer.seconds(simulation.duration)
    Process.send_after(self(), :cleanup, timeout)
    turn_launchers(simulation)

    {:noreply, state}
  end
  def handle_info(:cleanup, %{simulation: simulation} = state) do
    stop_remote_simulations(simulation)

    {:noreply, state}
  end

  defp create_group(%{id: id}) do
    :pg2.create(Fury.group(id))
  end

  defp get_group_members(%{id: id}) do
    :pg2.get_members(Fury.group(id))
  end

  defp start_remote_simulations(simulation) do
    simulation
    |> translate_simulation()
    |> @fury_bridge.start_simulation()
  end

  defp stop_remote_simulations(simulation) do
    simulation
    |> get_group_members()
    |> Enum.each(&GenServer.call(&1, :terminate))
  end

  defp translate_simulation(%{sessions: sessions} = simulation) do
    data = Map.from_struct(simulation)
    simulation = struct(Fury.Simulation, data)
    %{simulation | sessions: Enum.map(sessions, &translate_session/1)}
  end

  defp translate_session(session) do
    data = Map.from_struct(session)
    struct(Fury.Session, data)
  end

  defp turn_launchers(%{sessions: sessions}) do
    Enum.each(sessions, &Launcher.perform(&1.id))
  end

  defp name(id) do
    Simulation.name(id)
  end
end
