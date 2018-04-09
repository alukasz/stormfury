defmodule Fury.Session.SessionServer do
  use GenServer

  alias Fury.Client
  alias Fury.Session
  alias Fury.Simulation.Config

  require Logger

  def start_link(simulation_id, session_id) do
    opts = [simulation_id, session_id]

    GenServer.start_link(__MODULE__, opts, name: name(session_id))
  end

  def init([simulation_id, session_id]) do
    Logger.metadata(simulation: simulation_id)
    Logger.info("Starting session #{inspect session_id}")

    send(self(), :parse_scenario)
    {:ok, Config.session(simulation_id, session_id)}
  end

  def handle_call({:get_request, id}, _, %{requests: requests} = state) do
    request = Enum.at(requests, id, :error)

    {:reply, request, state}
  end
  def handle_call({:start_clients, ids}, _from, state) do
    %{id: session_id, simulation_id: simulation_id} = state
    Logger.debug("Starting #{length(ids)} clients for #{inspect session_id}")
    start_clients(simulation_id, session_id, ids)

    {:reply, :ok, state}
  end

  def handle_info(:parse_scenario, %{scenario: scenario} = state) do
    {:ok, requests} = Storm.DSL.parse(scenario)

    {:noreply, %{state | requests: requests ++ [:done]}}
  end

  defp start_clients(simulation_id, session_id, ids) do
    Enum.each ids, fn id ->
      {:ok, _} = Client.start(simulation_id, session_id, id)
    end
  end

  defp name(id) do
    Session.name(id)
  end
end
