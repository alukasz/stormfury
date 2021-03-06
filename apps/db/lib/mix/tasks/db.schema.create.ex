defmodule Mix.Tasks.Db.Schema.Create do
  use Mix.Task

  alias Db.Table

  def run(_args) do
    Mix.shell.info("Creating mnesia schema on #{node()}")

    with :ok <- create_schema(),
         :ok <- :mnesia.start(),
         {:atomic, :ok} <- create_table(Db.Simulation),
         {:atomic, :ok} <- create_table(Db.Session),
         {:atomic, :ok} <- create_table(Db.Metrics),
         {:atomic, :ok} <- create_table(Db.NodeMetrics) do
      Mix.shell.info("Created mnesia schema and tables")
    else
      {:error, reason} ->
        Mix.shell.error("Unable to create mnesia schema: #{inspect reason}")

      {:aborted, reason} ->
        Mix.shell.error("Unable to create mnesia table: #{inspect reason}")
    end
  end

  defp create_schema do
    :mnesia.create_schema([node()])
  end

  defp create_table(struct_mod) do
    Mix.shell.info("Creating table #{struct_mod}")

    struct_mod
    |> struct()
    |> Table.create_from_struct(disc_copies: [node()])
  end
end
