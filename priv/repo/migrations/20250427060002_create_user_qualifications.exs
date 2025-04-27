defmodule RosterApp.Repo.Migrations.CreateUserQualifications do
  use Ecto.Migration

  def change do
    create table(:user_qualifications) do
      add :user_id, references(:users, on_delete: :nothing)
      add :work_type_id, references(:work_types, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:user_qualifications, [:user_id])
    create index(:user_qualifications, [:work_type_id])
  end
end
