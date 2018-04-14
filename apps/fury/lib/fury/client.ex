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
    :metrics_ref,
    :transport,
    request: 0,
  ]
end
