defmodule Fury.TestServer do
  alias Fury.TestServer.HTTPHandler
  alias Fury.TestServer.WebSocketHandler

  def start_link(port, test) do
    state = %{port: port, test: test}

    dispatch = :cowboy_router.compile([
      {:_, [
          {'/', HTTPHandler, state},
          {'/websocket', WebSocketHandler, state}
        ]}
    ])

    ref = :"test_server_#{port}"

    {:ok, _} =
      :cowboy.start_clear(
        ref,
        [port: port],
        %{env: %{dispatch: dispatch}}
      )

    {:ok, ref}
  end

  def stop(ref) do
    :cowboy.stop_listener(ref)
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end
end
