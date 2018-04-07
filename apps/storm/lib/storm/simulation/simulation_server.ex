defmodule Storm.Simulation.SimulationServer do
  use GenServer

  alias Storm.Simulation

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
    send(self(), :initialize)

    {:ok, %State{simulation: simulation}}
  end

  def handle_call({:get_ids, number}, _, %{clients_started: started} = state) do
    new_started = started + number
    range = (started + 1)..new_started

    {:reply, range, %{state | clients_started: new_started}}
  end

  def handle_info(:initialize, %{simulation: simulation} = state) do
    start_remote_simulations(simulation)
    send(self(), :perform)

    {:noreply, state}
  end
  def handle_info(:perform, state) do
    timeout = :timer.seconds(state.simulation.duration)
    Process.send_after(self(), :cleanup, timeout)

    {:noreply, state}
  end
  def handle_info(:cleanup, state) do

    {:noreply, state}
  end

  defp start_remote_simulations(simulation) do
    simulation
    |> translate_simulation()
    |> @fury_bridge.start_simulation()
  end

  defp translate_simulation(simulation) do
    data = Map.from_struct(simulation)
    struct(Fury.Simulation, data)
  end

  defp name(id) do
    Simulation.name(id)
  end
end
