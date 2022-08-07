defmodule Trc.TestUtils do
  @moduledoc """
    Utils for Dataset tests
  """

  import Mox
  import Ecto.Changeset
  alias Trc.Model.Dataset
  alias Trc.Repo

  def mock_bitstring(bitstring, chunk_size \\ 2048) when is_bitstring(bitstring) do
    expect(Trc.Publisher.FileIOMock, :get_stream, fn _, _ ->
      {:ok, device} = StringIO.open(bitstring)
      IO.binstream(device, chunk_size)
    end)
  end

  def setup_dataset(name) do
    name
    |> to_string()
    |> Dataset.changeset()
    |> Repo.insert()
  end

  def add_entry({dataset_id, line}) do
    add_entry({dataset_id, DateTime.utc_now(), line})
  end

  def add_entry({dataset_id, timestamp, line}) do
    attrs = %{
      dataset_id: dataset_id,
      timestamp: timestamp,
      entry: line
    }

    %Trc.Model.DatasetEntry{}
    |> cast(attrs, [:dataset_id, :timestamp, :entry])
    |> Repo.insert()
  end

  def get_cache_key(dataset_id, last_ts, limit) do
    "#{dataset_id}$#{last_ts}$#{limit}"
  end
end
