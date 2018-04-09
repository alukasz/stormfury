defmodule Db.Table do
  alias Db.Record

  def create_from_struct(%mod{} = struct, opts \\ []) do
    opts = [{:attributes, Record.record_keys(struct)} | opts]

    :mnesia.create_table(mod, opts)
  end

  def exists?(table) do
    table in :mnesia.system_info(:tables)
  end
end
