defmodule Db.NodeMetrics do
  alias Db.NodeMetrics
  alias Db.Repo

  defstruct [
    :id, # a tuple of {simulation_id, node}
    :clients,
    :clients_connected,
    :messages_sent,
    :messages_received
  ]

  def insert(%NodeMetrics{} = node_metrics) do
    Repo.insert(node_metrics)
  end
end
