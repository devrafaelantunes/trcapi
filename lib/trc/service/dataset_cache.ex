defmodule Trc.Service.DatasetCache do
  @moduledoc """
    Represents the Dataset Cache. It uses Redis to store the dataset entries.
  """

  require Logger
  alias Trc.Model.DatasetEntry
  alias Trc.{Redis, Repo}

  @doc """
    Fetch the dataset entries by first hitting the Redis cache to check if it already has been
    populated.

    If the cache is populated, it will return the entries. If not, the function will populate
    the cache then return the entries.
  """
  @spec get_entries(dataset_id :: integer(), last_ts :: integer(), limit :: integer()) :: list()
  def get_entries(dataset_id, last_ts, limit)
      when is_integer(dataset_id) and is_integer(last_ts) and is_integer(limit) do
    key = get_cache_key(dataset_id, last_ts, limit)

    case Redis.get(key) do
      nil ->
        Logger.info("#{key}: Cache miss; fetching from database and populating cache")

        entries =
          dataset_id
          |> DatasetEntry.list(last_ts, limit)
          |> Repo.all()
          |> Enum.map(&DatasetEntry.format/1)

        Redis.set(key, entries)
        entries

      values when is_list(values) ->
        Logger.info("#{key}: Cache hit; returning entries directly from cache")
        values
    end
  end

  defp get_cache_key(dataset_id, last_ts, limit) do
    "#{dataset_id}$#{last_ts}$#{limit}"
  end
end
