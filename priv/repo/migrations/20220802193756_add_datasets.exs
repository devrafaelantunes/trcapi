defmodule Trc.Repo.Migrations.AddDatasets do
  use Ecto.Migration

  def change do
    create table(:datasets) do
      add(:name, :text, null: false)
    end
  end
end
