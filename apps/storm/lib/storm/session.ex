defmodule Storm.Session do
  defstruct [
    :id,
    :simulation_id,
    :clients,
    :arrival_rate,
    :scenario,
    :dispatcher_pid,
    clients_started: 0,
    state: :ready
  ]
end
