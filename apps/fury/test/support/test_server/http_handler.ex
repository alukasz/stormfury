defmodule Fury.TestServer.HTTPHandler do
  def init(req, %{test: test, port: port} = state) do
    send(test, {:http_request, port, req})
    resp = :cowboy_req.reply(200, %{}, "ok", req)

    {:ok, resp, state}
  end
end
