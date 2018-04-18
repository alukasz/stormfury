defmodule Db.NodeMetrics do
  alias Db.NodeMetrics
  alias Db.Repo
  alias Db.Util

  defstruct [
    :id, # a tuple of {simulation_id, node}
    :clients,
    :clients_connected,
    :messages_sent,
    :messages_received
  ]

  def insert(%NodeMetrics{id: {_, _}} = node_metrics) do
    Repo.insert(node_metrics)
  end

  def get_by_simulation_id(simulation_id) do
    %NodeMetrics{}
    |> Util.match_spec(:id, {simulation_id, :_})
    |> Repo.match()
  end
end
