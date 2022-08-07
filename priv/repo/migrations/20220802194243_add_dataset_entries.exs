defmodule Trc.Repo.Migrations.AddDatasetEntries do
  use Ecto.Migration

  def change do
    create table(:dataset_entries, primary_key: false) do
      add(:dataset_id, :integer, null: false)
      add(:timestamp, :utc_datetime_usec, null: false)
      add(:entry, :text, null: false)
    end
  end
end
