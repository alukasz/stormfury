defmodule Fury.Protocol do
  @type state :: term
  @type request :: {atom, String.t}
  @type data :: binary

  @callback init :: state

  @callback format(request, state) ::
              {:ok, data, state}
              | {:error, term}

  @callback handle_data(data, state) ::
              {:ok, state}
              | {:error, term}
end
