defmodule Fury.Protocol.PhoenixChannels do
  @behaviour Fury.Protocol

  @impl true
  def init do
    %{}
  end

  @impl true
  def format({{:join, topic}, data}, state) do
    push(topic, "phx_join", data, state)
  end
  def format({{:push, topic, event}, data}, state) do
    push(topic, event, data, state)
  end

  @impl true
  def handle_data(_, session) do
    {:ok, session}
  end

  defp push(topic, event, payload, state) do
    payload = Poison.encode!(%{topic: topic, event: event,
                               payload: payload, ref: "1"})

    {:ok, payload, state}
  end
end
