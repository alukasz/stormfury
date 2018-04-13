defmodule Fury.Client.ClientFSM do
  @behaviour :gen_statem

  alias Fury.Client
  alias Fury.Session
  alias Storm.DSL.Util
  alias Fury.Client.ClientSupervisor

  def start_link(%Client{} = client) do
    :gen_statem.start_link(__MODULE__, client, [])
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  def init(%{protocol_mod: protocol_mod} = client) do
    protocol_state = protocol_mod.init()

    {:ok, :disconnected, %{client | protocol_state: protocol_state}}
  end

  def callback_mode do
    [:handle_event_function, :state_enter]
  end

  def handle_event(:enter, _, :disconnected, _) do
    {:keep_state_and_data, [{:state_timeout, 1000, :connect}]}
  end
  def handle_event(:enter, _, :connected, _) do
    {:keep_state_and_data, make_request()}
  end
  def handle_event(:state_timeout, :connect, _, client) do
    case start_transport(client) do
      {:ok, pid} ->
        ref = Process.monitor(pid)
        {:keep_state, %{client | transport: pid, transport_ref: ref}}

      {:error, _} ->
        {:next_state, :disconnected, client}
    end
  end
  def handle_event(:info, :transport_connected, _, client) do
    {:next_state, :connected, client}
  end
  def handle_event(:info, {:transport_data, data}, _, client) do
    %{protocol_mod: protocol_mod, protocol_state: protocol_state} = client

    {:ok, protocol_state} = protocol_mod.handle_data(data, protocol_state)

    {:keep_state, %{client | protocol_state: protocol_state}}
  end
  def handle_event(:info, {:DOWN, ref, _, _, _}, _, %{transport_ref: ref} = client) do
    {:next_state, :disconnected, %{client | transport: nil,
                                   transport_ref: nil,
                                   request: 0}}
  end
  def handle_event(:timeout, :make_request, :disconnected, _) do
    :keep_state_and_data
  end
  def handle_event(:timeout, :make_request, :connected, client) do
    %{request: request_id, session_id: session_id} = client

    case Session.get_request(session_id, request_id) do
      :error ->
        :keep_state_and_data

      :done ->
        :keep_state_and_data

      {:think, time} ->
        {:keep_state, %{client | request: request_id + 1}, make_request(time)}

      request ->
        protocol_state = do_make_request(request, client)
        client = %{client | protocol_state: protocol_state,
                  request: request_id + 1}

        {:keep_state, client, make_request()}
    end
  end

  def terminate(_reason, _state, _data) do
    :ok
  end

  def code_change(_old_vsn, state, client, _extra) do
    {:ok, state, client}
  end

  defp start_transport(%{supervisor_pid: pid, transport_mod: mod, url: url}) do
    opts = [url: url, client: self()]

    ClientSupervisor.start_transport(pid, mod, opts)
  end

  defp do_make_request(request, client) do
    %{id: id, transport_mod: transport_mod, transport: transport,
      protocol_mod: protocol_mod, protocol_state: protocol_state} = client

    request = put_client_id(request, id)
    with {:ok, request, new_protocol_state} <- protocol_mod.format(request, protocol_state),
          :ok <- transport_mod.push(transport, request) do
      new_protocol_state
    else
      _ -> protocol_state
    end
  end

  defp put_client_id({_, payload} = request, id) do
    payload = Util.replace_vars(payload, %{"id" => id})
    put_elem(request, 1, payload)
  end

  defp make_request(time \\ 0) do
    [{:timeout, :timer.seconds(time), :make_request}]
  end
end
