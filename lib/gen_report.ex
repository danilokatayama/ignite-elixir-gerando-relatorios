defmodule GenReport do
  alias GenReport.Parser

  def build(filename) do
    filename
    |> Parser.parse_file()
    |> Enum.reduce(report_acc(), fn line, report -> sum_values(line, report) end)
  end

  def build(), do: {:error, "Insira o nome de um arquivo"}

  def build_from_many(filenames) when not is_list(filenames) do
    {:error, "Please, provide a list of strings"}
  end

  def build_from_many(filenames) do
    result =
      filenames
      |> Task.async_stream(&build/1)
      |> Enum.reduce(
        report_acc(),
        fn {:ok,
            %{
              "all_hours" => all_hours,
              "hours_per_month" => hours_per_month,
              "hours_per_year" => hours_per_year
            }},
           report ->
          all_hours = merge(all_hours, report["all_hours"])

          hours_per_month =
            Map.merge(hours_per_month, report["hours_per_month"], fn _k, v1, v2 ->
              merge(v1, v2)
            end)

          hours_per_year =
            Map.merge(hours_per_year, report["hours_per_year"], fn _k, v1, v2 ->
              merge(v1, v2)
            end)

          build_report(all_hours, hours_per_month, hours_per_year)
        end
      )

    {:ok, result}
  end

  defp sum_values([name, hours, _day, month, year], %{
         "all_hours" => all_hours,
         "hours_per_month" => hours_per_month,
         "hours_per_year" => hours_per_year
       }) do
    all_hours = merge(all_hours, %{name => hours})

    hours_per_month =
      Map.merge(hours_per_month, %{name => %{month => hours}}, fn _k, v1, v2 -> merge(v1, v2) end)

    hours_per_year =
      Map.merge(hours_per_year, %{name => %{year => hours}}, fn _k, v1, v2 -> merge(v1, v2) end)

    build_report(all_hours, hours_per_month, hours_per_year)
  end

  defp merge(map1, map2), do: Map.merge(map1, map2, fn _k, v1, v2 -> v1 + v2 end)

  defp report_acc() do
    build_report(%{}, %{}, %{})
  end

  defp build_report(
         all_hours,
         hours_per_month,
         hours_per_year
       ) do
    %{
      "all_hours" => all_hours,
      "hours_per_month" => hours_per_month,
      "hours_per_year" => hours_per_year
    }
  end
end
