defmodule Fury.Transport do
  @type t :: pid

  @callback connect(String.t, Keyword.t) :: {:ok, t} | {:error, term}
  @callback push(t, map) :: :ok | {:error, term}
  @callback close(t) :: :ok | {:error, term}
end
