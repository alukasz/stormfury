defmodule Db.Repo do
  alias Db.Record

  def get(table, id) do
    transaction = fn -> :mnesia.read(table, id) end

    case :mnesia.transaction(transaction) do
      {:atomic, []} ->
        nil

      {:atomic, [record]} ->
        Record.to_struct(record)

      {:aborted, reason} ->
        {:error, reason}
    end
  end

  def insert(%_{} = struct) do
    transaction = fn ->
      struct
      |> Record.from_struct()
      |> :mnesia.write()
    end

    case :mnesia.transaction(transaction) do
      {:atomic, :ok} ->
        :ok

      {:aborted, reason} ->
        {:error, reason}
    end
  end

  def match(match_spec) do
    transaction = fn -> :mnesia.match_object(match_spec) end

    case :mnesia.transaction(transaction) do
      {:atomic, records} ->
        Enum.map(records, &Record.to_struct/1)

      {:aborted, reason} ->
        {:error, reason}
    end
  end
end
