defmodule Fury.Client do
  alias Fury.Client.ClientSupervisor

  defstruct [
    :id,
    :session_id,
    :simulation_id,
    :session_pid,
    :url,
    :transport_mod,
    :protocol_mod,
    :protocol_state,
    request: 0,
    transport: :not_connected
  ]

  def start(simulation_id, session_id, id) do
    ClientSupervisor.start_child(supervisor_name(simulation_id), session_id, id)
  end

  def connect(transport_mod, url) do
    transport_mod.connect(url, client: self())
  end

  def make_request(transport_mod, transport, protocol_mod, state, request) do
    with {:ok, request, new_state} <- protocol_mod.format(request, state),
         :ok <- transport_mod.push(transport, request) do
        new_state
    else
      _ -> state
    end
  end

  def supervisor_name(simulation_id) do
    {:via, Registry, {Fury.Registry.ClientSupervisor, simulation_id}}
  end
end
