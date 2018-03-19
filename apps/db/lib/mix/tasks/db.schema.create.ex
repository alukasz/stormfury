defmodule Mix.Tasks.Db.Schema.Create do
  use Mix.Task

  alias Db.Table

  def run(_args) do
    with :ok <- create_schema(),
         :ok <- :mnesia.start(),
         {:atomic, :ok} <- create_table(Storm.Simulation),
         {:atomic, :ok} <- create_table(Storm.Session) do
      Mix.shell.info("Created mnesia schema and tables")
    else
      {:error, reason}->
        Mix.shell.error("Unable to create mnesia schema: #{inspect reason}")

      {:aborted, reason}->
        Mix.shell.error("Unable to create mnesia table: #{inspect reason}")
    end
  end

  defp create_schema do
    :mnesia.create_schema([node()])
  end

  defp create_table(struct_mod) do
    struct_mod
    |> struct()
    |> Table.create_from_struct(disc_copies: [node()])
  end
end
