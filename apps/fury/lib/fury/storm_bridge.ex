defmodule Fury.StormBridge do
  @callback send_metrics(term, term) :: :ok
end
