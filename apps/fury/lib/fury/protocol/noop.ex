defmodule Fury.Protocol.Noop do
  @behaviour Fury.Protocol

  @impl true
  def init do
    %{}
  end

  @impl true
  def format(payload, _) do
    {:ok, payload}
  end

  @impl true
  def handle_data(_, session) do
    {:ok, session}
  end
end
