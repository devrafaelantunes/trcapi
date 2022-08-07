defmodule Trc.Model.Dataset do
  @moduledoc """
    Represent the `datasets` schema and queries
  """

  use Ecto.Schema

  import Ecto.{Changeset, Query}

  schema "datasets" do
    field :name, :string
  end

  @spec changeset(%{name: atom()}) :: Ecto.Changeset
  def changeset(name) do
    %__MODULE__{}
    |> cast(%{name: to_string(name)}, [:name])
    |> validate_length(:name, min: 1)
  end

  @doc """
    Queries the dataset by its id
  """
  @spec query_id(dataset :: integer()) :: Ecto.Query
  def query_id(dataset) do
    from(d in __MODULE__,
      where: d.name == ^dataset,
      select: d.id
    )
  end
end
