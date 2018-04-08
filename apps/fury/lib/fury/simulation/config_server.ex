defmodule Fury.Simulation.ConfigServer do
  use GenServer

  alias Fury.Client
  alias Fury.Session
  alias Fury.Simulation
  alias Fury.Simulation.Config

  def start_link(%Simulation{} = simulation) do
    GenServer.start_link(__MODULE__, simulation, name: name(simulation))
  end

  def init(simulation) do
    {:ok, simulation}
  end

  def handle_call(:simulation, _from, simulation) do
    {:reply, simulation, simulation}
  end

  def handle_call({:session, id}, _from, %{sessions: sessions} = simulation) do
    session =
      Enum.find sessions, :error, fn
        %Session{id: ^id} -> true
        _ -> false
      end

    {:reply, session, simulation}
  end

  def handle_call(:client, _from, simulation) do
    client = %Client{
      url: simulation.url,
      transport_mod: simulation.transport_mod,
      protocol_mod: simulation.protocol_mod
    }

    {:reply, client, simulation}
  end

  defp name(%{id: id}) do
    Config.name(id)
  end

end
