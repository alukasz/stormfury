defmodule Fury.TestServer.Port do
  use Agent

  def start do
    Agent.start(fn -> 5050 end, name: __MODULE__)
  end

  def next do
    Agent.get_and_update __MODULE__, fn port ->
      {port, port + 1}
    end
  end
end
