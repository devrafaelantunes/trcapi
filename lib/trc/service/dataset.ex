defmodule Trc.Service.Dataset do
  @moduledoc """
    This module parses and sets the Datasets. It also fetches them from the database.
  """

  @limit_default 50
  @epoch_start 0

  alias Trc.Model.Dataset
  alias Trc.Service.DatasetCache
  alias Trc.Repo

  @doc """
    Gets the `dataset` by its name
  """
  @spec get_by_name(dataset_name :: atom()) :: Dataset
  def get_by_name(dataset_name) when is_atom(dataset_name),
    do: dataset_name |> to_string() |> get_by_name()

  @spec get_by_name(dataset_name :: String.t()) :: Dataset
  def get_by_name(dataset_name), do: Repo.get_by(Dataset, name: dataset_name)

  @spec get_by_name!(dataset_name :: atom()) :: Dataset
  def get_by_name!(dataset_name) when is_atom(dataset_name),
    do: dataset_name |> to_string() |> get_by_name!()

  @spec get_by_name!(dataset_name :: String.t()) :: Dataset
  def get_by_name!(dataset_name), do: Repo.get_by!(Dataset, name: dataset_name)

  @doc """
    Inserts the Dataset into the database if it does not exist. If the dataset is
    already stored, it will return it.
  """
  @spec setup(dataset :: atom() | String.t()) :: {:ok, Dataset} | {:error, Ecto.Changeset}
  def setup(dataset) do
    case get_by_name(dataset) do
      nil ->
        dataset
        |> Dataset.changeset()
        |> Repo.insert()

      %Dataset{} = ds ->
        {:ok, ds}
    end
  end

  @doc """
    Gets the dataset entries based on its id and last timestamp. The amount of returned entries
    is based on the limit argument.
  """
  @spec get_entries(
          dataset :: integer(),
          last_ts :: nil | integer() | any(),
          limit :: nil | integer() | any()
        ) :: {:ok, entries :: list()} | {:error, String.t()}
  def get_entries(dataset, last_ts, limit) do
    last_ts = get_last_ts(last_ts)
    limit = get_limit(limit)

    case get_dataset_id(dataset) do
      dataset_id when is_integer(dataset_id) ->
        {:ok, DatasetCache.get_entries(dataset_id, last_ts, limit)}

      nil ->
        {:error, "Dataset not found"}
    end
  end

  # Returns the dataset id
  defp get_dataset_id(dataset) do
    dataset
    |> Dataset.query_id()
    |> Repo.one()
  end

  defp get_last_ts(nil), do: @epoch_start

  # Parses the last_timestamp value, if not parsable it will return the default value
  defp get_last_ts(ts) do
    case Integer.parse(ts) do
      {ts, _} -> ts
      :error -> @epoch_start
    end
  end

  # Parses the limit value, if not parsable it will return the default value
  defp get_limit(nil), do: @limit_default
  defp get_limit(limit) when is_integer(limit) and limit >= 1, do: limit
  defp get_limit(limit) when is_integer(limit) and limit < 1, do: @limit_default

  defp get_limit(limit) do
    case Integer.parse(limit) do
      {limit, _} ->
        if limit >= 1 do
          limit
        else
          @limit_default
        end

      :error ->
        @limit_default
    end
  end
end
