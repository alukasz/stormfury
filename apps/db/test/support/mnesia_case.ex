defmodule Db.MnesiaCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Db.MnesiaCase

      @table Db.TestStruct
    end
  end

  setup do
    :mnesia.clear_table(Db.TestStruct)
    :mnesia.clear_table(Db.Simulation)
    :mnesia.clear_table(Db.Session)

    :ok
  end

  def insert_record(record) do
    transaction = fn -> :mnesia.write(record) end
    {:atomic, :ok} = :mnesia.transaction(transaction)

    record
  end

  def record_exists?(table, id) do
    transaction = fn -> :mnesia.read(table, id) end

    match?({:atomic, [_]}, :mnesia.transaction(transaction))
  end

  def get_record(table, id) do
    transaction = fn -> :mnesia.read(table, id) end
    {:atomic, [record]} = :mnesia.transaction(transaction)

    record
  end
end
