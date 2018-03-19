defmodule Mix.Tasks.Db.Schema.Drop do
  use Mix.Task

  def run(_args) do
    case delete_schema() do
      :ok ->
        Mix.shell.info("Dropped mnesia")

      {:error, reason} ->
        Mix.shell.error("Unable to drop mnesia schema: #{inspect reason}")
    end
  end

  defp delete_schema do
    :mnesia.delete_schema([node()])
  end
end
