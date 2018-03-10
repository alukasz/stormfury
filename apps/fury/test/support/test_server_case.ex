defmodule Fury.TestServerCase do
  use ExUnit.CaseTemplate

  alias Fury.TestServer
  alias Fury.TestServer.Port

  setup do
    {ref, port} = start_test_server()

    on_exit fn ->
      TestServer.stop(ref)
    end

    {:ok, port: port, ws_url: "ws://localhost:#{port}/websocket",
     http_url: "http://localhost:#{port}"}
  end

  defp start_test_server do
    port = Port.next()
    {:ok, ref} = TestServer.start_link(port, self())

    {ref, port}
  end
end
