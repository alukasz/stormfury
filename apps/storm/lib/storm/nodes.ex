defmodule Storm.Nodes do
  @type host :: String.t

  @callback start_node(host) :: {:ok, node() | :error, term}
  @callback stop_node(node) :: :ok

  @storm_host Application.fetch_env!(:storm, :host)

  def start_node(host) do
    host
    |> to_charlist()
    |> allow_inet_boot()
    |> start_slave()
    |> case do
         {:ok, node} -> start_fury(node)
         error -> error
       end
  end

  def stop_node(node) do
    :slave.stop(node)
  end

  defp allow_inet_boot(host) do
    {:ok, ipv4} = :inet.parse_ipv4_address(host)
    :erl_boot_server.add_slave(ipv4)

    host
  end

  defp start_slave(host) do
    :slave.start(host, :fury, beam_args())
  end

  defp beam_args do
    cookie = :erlang.get_cookie()

    to_charlist("-loader inet -hosts #{@storm_host} -setcookie #{cookie}")
  end

  defp start_fury(node) do
    with :ok <- load_paths(node),
         {:ok, _} <- start_application(node) do
      {:ok, node}
    else
      error -> error
    end
  end

  defp load_paths(node) do
    :rpc.block_call(node, :code, :add_paths, [:code.get_path()])
  end

  defp start_application(node) do
    :rpc.block_call(node, Application, :ensure_all_started, [:fury])
    :rpc.block_call(node, Application, :ensure_all_started, [:db])
  end
end
