defmodule Fury.Protocol do
  @type session :: term
  @type request :: {atom, String.t}
  @type data :: binary

  @callback init :: session

  @callback format(request, session) ::
              {:ok, data}
              | {:error, term}

  @callback handle_data(data, session) ::
              {:ok, session}
              | {:error, term}
end
