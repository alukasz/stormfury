defmodule Storm.NodeMonitorsSupervisor do
  use DynamicSupervisor

  alias Storm.NodeMonitor

  def start_link(nodes) do
    {:ok, pid} = DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
    start_children(nodes)

    {:ok, pid}
  end

  def start_child(node) do
    DynamicSupervisor.start_child(__MODULE__, {NodeMonitor, node})
  end

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  defp start_children(nodes) do
    Enum.each(nodes, &start_child/1)
  end
end
