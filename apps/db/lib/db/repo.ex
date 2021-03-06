defmodule Db.Repo do
  alias Db.Record

  def get(table, id) do
    operation = fn -> :mnesia.read(table, id) end

    case transaction(operation) do
      [] ->
        nil

      [record] ->
        Record.to_struct(record)

      error ->
        error
    end
  end

  def insert(%_{} = struct) do
    operation = fn ->
      struct
      |> Record.from_struct()
      |> :mnesia.write()
    end

    case transaction(operation) do
      :ok ->
        :ok

      error ->
        error
    end
  end

  def update(table, id, attrs) do
    operation = fn ->
      with %_{} = struct <- get(table, id),
           attrs = Enum.into(attrs, %{}),
           struct = Map.merge(struct, attrs),
           :ok <- insert(struct) do
        struct
      else
        error -> error
      end
    end

    case transaction(operation) do
      %_{} = struct ->
        struct

      _ ->
        {:error, :not_found}
    end
  end

  def match(match_spec) do
    operation = fn -> :mnesia.match_object(match_spec) end

    case transaction(operation) do
      records when is_list(records) ->
        Enum.map(records, &Record.to_struct/1)

      error ->
        error
    end
  end

  def transaction(operations) do
    case :mnesia.transaction(operations) do
      {:atomic, result} ->
        result

      {:aborted, reason} ->
        {:error, reason}
    end
  end

  def abort_transaction(message) do
    :mnesia.abort(message)
  end
end
