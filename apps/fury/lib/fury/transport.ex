defmodule Fury.Transport do
  defmacro __using__(_) do
    quote location: :keep do
      @behaviour Fury.Transport

      def child_spec(opts) do
        %{
          id: __MODULE__,
          start: {__MODULE__, :connect, [opts]},
          type: :worker,
          restart: :temporary,
          shutdown: 500
        }
      end

      defoverridable child_spec: 1
    end
  end

  @type t :: pid

  @callback connect(Keyword.t) :: {:ok, t} | {:error, term}
  @callback push(t, String.t) :: :ok | {:error, term}
  @callback close(t) :: :ok | {:error, term}
end
