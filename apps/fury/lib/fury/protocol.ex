defmodule Fury.Protocol do
  @type session :: term
  @type payload :: term
  @type data :: binary

  @callback init :: session
  @callback format(payload, session) :: {:ok, data} | {:error, term}
  @callback handle_data(data, session) :: {:ok, session} | {:error, term}
end
