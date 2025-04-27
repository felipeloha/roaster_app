defmodule RosterApp.Repo.Migrations.CreateAbsences do
  use Ecto.Migration

  def change do
    create table(:absences) do
      add :unavailable_days, {:array, :integer}
      add :user_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:absences, [:user_id])
  end
end
