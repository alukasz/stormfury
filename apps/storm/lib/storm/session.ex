defmodule Storm.Session do
  defstruct [
    :id,
    :simulation_id,
    :clients,
    :arrival_rate,
    :scenario,
    clients_started: 0,
    state_pid: nil
  ]
end
