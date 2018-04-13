defmodule Fury.Session.SessionServer do
  use GenServer

  alias Fury.Client
  alias Fury.Session
  alias Fury.State
  alias Fury.Cache
  alias Fury.Session.SessionSupervisor
  alias Fury.Client.ClientsSupervisor

  require Logger

  def start_link(%{id: id} = session) do
    GenServer.start_link(__MODULE__, session, name: name(id))
  end

  defp name(id) do
    Session.name(id)
  end

  def init(state) do
    Logger.metadata(simulation: state.simulation_id)
    Logger.info("Starting session #{inspect state.id}")
    send(self(), :start_clients_supervisor)

    {:ok, parse_scenario(state)}
  end

  def handle_call({:get_request, id}, _, %{requests_cache: cache} = state) do
    request =
      case Cache.get(cache, id) do
        {:ok, request} -> request
        error -> error
      end

    {:reply, request, state}
  end

  def handle_cast({:start_clients, ids}, %{id: session_id} = state) do
    Logger.debug("Starting #{length(ids)} clients for #{inspect session_id}")
    start_clients(state, ids)

    {:noreply, state}
  end

  def handle_info(:start_clients_supervisor, state) do
    {:ok, pid} = SessionSupervisor.start_clients_supervisor(state.supervisor_pid)
    ref = Process.monitor(pid)
    case State.get_ids(state.simulation_id, state.id) do
      [] -> :ok
      ids -> GenServer.cast(self(), {:start_clients, ids})
    end

    {:noreply, %{state | clients_sup_pid: pid, clients_sup_ref: ref}}
  end
  def handle_info({:DOWN, ref, _, _, _}, %{clients_sup_ref: ref} = state) do
    send(self(), :start_clients_supervisor)

    {:noreply, %{state | clients_sup_pid: nil, clients_sup_ref: nil}}
  end

  def parse_scenario(%{scenario: scenario} = state) do
    {:ok, requests} = Storm.DSL.parse(scenario)

    %{state | requests_cache: build_cache(requests)}
  end

  defp build_cache(requests) do
    cache = Cache.new(:requests_cache)
    requests
    |> Kernel.++([:done])
    |> Enum.with_index()
    |> Enum.each(fn {request, id} ->
      Cache.put(cache, id, request)
    end)

    cache
  end

  defp start_clients(%{clients_sup_pid: pid} = state, ids) do
    Enum.each ids, fn id ->
      state = client_state(state, id)
      {:ok, _} = ClientsSupervisor.start_child(pid, state)
    end
    State.add_ids(state.simulation_id, state.id, ids)
  end

  defp client_state(session, id) do
    %Client{
      id: id,
      session_id: session.id,
      simulation_id: session.simulation_id,
      session_pid: self(),
      url: session.url,
      protocol_mod: session.protocol_mod,
      transport_mod: session.transport_mod,
    }
  end
end
