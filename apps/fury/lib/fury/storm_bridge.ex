defmodule Fury.StormBridge do
  alias Fury.Protocol

  @callback get_request(Protocol.session, term) ::
              {:ok, Protocol.request}
              | {:error, term}
end
