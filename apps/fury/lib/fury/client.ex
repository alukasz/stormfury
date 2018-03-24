defmodule Fury.Client do
  def connect(transport_mod, url) do
    transport_mod.connect(url, client: self())
  end

  def make_request(transport_mod, transport, protocol_mod, state, request) do
    with {:ok, request, new_state} <- protocol_mod.format(request, state),
         :ok <- transport_mod.push(transport, request) do
        new_state
    else
      _ -> state
    end
  end
end
