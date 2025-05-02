defmodule RosterApp.Repo.Migrations.CreateShifts do
  use Ecto.Migration

  def change do
    create table(:shifts) do
      add :start_time, :utc_datetime
      add :end_time, :utc_datetime
      add :description, :string
      add :work_type_id, references(:work_types, on_delete: :nothing)
      add :department_id, references(:departments, on_delete: :nothing)
      add :assigned_user_id, references(:users, on_delete: :nothing)
      add :tenant_id, references(:tenants, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:shifts, [:work_type_id])
    create index(:shifts, [:department_id])
    create index(:shifts, [:assigned_user_id])
    create index(:shifts, [:tenant_id])
  end
end
