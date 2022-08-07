defmodule TrcWeb.DatasetController do
  use TrcWeb, :controller

  alias Trc.Service.Dataset

  def index(%{params: params} = conn, _) do
    conn = conn |> put_resp_header("content-type", "application/json")

    params = %{
      dataset: params["dataset"],
      last_ts: params["last_ts"],
      limit: params["limit"]
    }

    with {:ok, {dataset, last_ts, limit}} <- validate_index_params(params),
         {:ok, entries} <- Dataset.get_entries(dataset, last_ts, limit) do
      send_resp(conn, 200, entries |> Jason.encode!())
    else
      {:error, reason} ->
        send_resp(conn, 400, %{error: reason} |> Jason.encode!())
    end
  end

  defp validate_index_params(%{dataset: nil}), do: {:error, "Dataset not specified"}
  defp validate_index_params(%{dataset: ""}), do: {:error, "Dataset not specified"}
  defp validate_index_params(p), do: {:ok, {p.dataset, p.last_ts, p.limit}}
end
