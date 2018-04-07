defmodule Storm.NodesTest do
  use ExUnit.Case, async: true

  alias Storm.Nodes

  # @host Application.fetch_env!(:storm, :host)

  # @tag timeout: 2000
  # test "starts and stops slave node" do
  #   assert {:ok, node} = Nodes.start_node(@host)
  #   assert_slave_started(node)

  #   assert :ok = Nodes.stop_node(node)
  #   assert_slave_stopped(node)
  # end

  # defp assert_slave_started(node) do
  #   assert node == :"fury@#{@host}"
  #   assert Node.ping(node) == :pong
  #   assert node in Node.list()
  # end

  # defp assert_slave_stopped(node) do
  #   assert Node.ping(node) == :pang
  #   refute node in Node.list()
  # end
end
