defmodule Storm.NodeMonitor do
  use GenServer

  require Logger

  @interval :timer.seconds(1)

  def start_link(node) do
    GenServer.start_link(__MODULE__, node, name: name(node))
  end

  def init(node) do
    :ok = :net_kernel.monitor_nodes(true)
    ping()

    {:ok, node}
  end

  def handle_info(:ping, node) do
    case Node.ping(node) do
      :pang -> ping()
      _ -> :ok
    end

    {:noreply, node}
  end
  def handle_info({:nodeup, node}, node) do
    Logger.info("Connection to #{node} established.")
    join_mnesia_cluster(node)

    {:noreply, node}
  end
  def handle_info({:nodeup, _}, node) do
    {:noreply, node}
  end
  def handle_info({:nodedown, node}, node) do
    Logger.warn("Lost connection to #{node}, attempting to reestablish...")
    ping()

    {:noreply, node}
  end
  def handle_info({:nodedown, _}, node) do
    {:noreply, node}
  end

  defp ping do
    Process.send_after(self(), :ping, @interval)
  end

  defp name(node) do
    Module.concat(__MODULE__, node)
  end

  defp join_mnesia_cluster(node) do
    :mnesia.change_config(:extra_db_nodes, [node])
  end
end
