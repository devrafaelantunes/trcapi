defmodule Trc.Model.DatasetEntry do
  @moduledoc """
    Represents the `dataset_entries` schema and queries
  """

  # Typespec
  @type dataset_id :: integer()
  @type limit :: integer()

  use Ecto.Schema
  import Ecto.Query

  @primary_key false
  schema "dataset_entries" do
    field :dataset_id, :integer
    field :timestamp, :utc_datetime_usec
    field :entry, :string
  end

  @doc """
    Formats the timestamp from String to DateTime
  """
  @spec format(map()) :: map()
  def format(%{timestamp: timestamp} = entry) do
    %{entry | timestamp: DateTime.to_unix(timestamp, :microsecond)}
  end

  @doc """
    Lists the Dataset Entries based on the Dataset ID when `last_ts` is an integer
  """
  @spec list(dataset_id(), last_ts :: integer(), limit()) :: Ecto.Query
  def list(dataset_id, last_ts, limit) when is_integer(last_ts) do
    list(dataset_id, DateTime.from_unix!(last_ts, :microsecond), limit)
  end

  # Same as function above but this will match when the `last_ts` is already parsed into DateTime struct
  @spec list(dataset_id(), last_ts :: DateTime, limit()) :: Ecto.Query
  def list(dataset_id, last_ts, limit) do
    from(de in __MODULE__,
      where: de.dataset_id == ^dataset_id,
      where: de.timestamp > ^last_ts,
      order_by: de.timestamp,
      limit: ^limit,
      select: %{timestamp: de.timestamp, entry: de.entry}
    )
  end
end
