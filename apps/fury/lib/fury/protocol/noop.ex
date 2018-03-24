defmodule Fury.Protocol.Noop do
  @behaviour Fury.Protocol

  @impl true
  def init do
    %{}
  end

  @impl true
  def format({:push, data}, state) do
    {:ok, data, state}
  end

  @impl true
  def handle_data(_, session) do
    {:ok, session}
  end
end
