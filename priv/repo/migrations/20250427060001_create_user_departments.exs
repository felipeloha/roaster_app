defmodule RosterApp.Repo.Migrations.CreateUserDepartments do
  use Ecto.Migration

  def change do
    create table(:user_departments) do
      add :user_id, references(:users, on_delete: :nothing)
      add :department_id, references(:departments, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:user_departments, [:user_id])
    create index(:user_departments, [:department_id])
  end
end
