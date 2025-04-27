defmodule RosterApp.Repo.Migrations.CreateWorkTypes do
  use Ecto.Migration

  def change do
    create table(:work_types) do
      add :name, :string

      timestamps(type: :utc_datetime)
    end
  end
end
