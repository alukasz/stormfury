defmodule Storm.Metrics.MetricsCSVExporter do
  def export(simulation_id) do
    simulation_id
    |> Db.Metrics.get_by_simulation_id()
    |> sort_by_time()
    |> format_to_csv()
    |> write_to_file(simulation_id)
  end

  defp sort_by_time(metrics) do
    Enum.sort_by(metrics, &elem(&1.id, 1))
  end

  defp format_to_csv(metrics) do
    header = format_csv_header(metrics)
    rows = format_csv_rows(metrics)

    [header | rows]
  end

  defp format_csv_header([metric | _]) do
    metric
    |> metrics_struct_to_list()
    |> Keyword.keys()
    |> Enum.join(",")
  end

  defp format_csv_rows(metrics) do
    Enum.map(metrics, &format_csv_row/1)
  end

  defp format_csv_row(metric) do
    metric
    |> metrics_struct_to_list()
    |> Keyword.values()
    |> Enum.join(",")
  end

  defp metrics_struct_to_list(metric) do
    metric
    |> Map.from_struct()
    |> Map.delete(:id)
    |> Map.to_list()
    |> Enum.sort_by(&elem(&1, 0))
  end

  defp write_to_file(metrics, simulation_id) do
    File.write("#{simulation_id}.csv", Enum.join(metrics, "\n"))
  end
end
