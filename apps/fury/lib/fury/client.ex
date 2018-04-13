defmodule Fury.Client do
  defstruct [
    :id,
    :session_id,
    :simulation_id,
    :session_pid,
    :url,
    :transport_mod,
    :transport_ref,
    :protocol_mod,
    :protocol_state,
    :supervisor_pid,
    request: 0,
    transport: :not_connected
  ]
end
