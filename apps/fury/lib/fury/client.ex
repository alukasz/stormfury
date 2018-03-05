defmodule Fury.Client do
  def connect(transport_mod, url) do
    transport_mod.connect(url, client: self())
  end

  def make_request(transport_mod, transport, protocol_mod, request) do
    case protocol_mod.format(request, []) do
      {:ok, request} -> transport_mod.push(transport, request)
      error -> error
    end
  end
end
