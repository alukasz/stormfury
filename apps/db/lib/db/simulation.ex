defmodule Db.Simulation do
  defstruct [
    :id,
    :url,
    :duration,
    :protocol_mod,
    :transport_mod,
    sessions: []
  ]
end
