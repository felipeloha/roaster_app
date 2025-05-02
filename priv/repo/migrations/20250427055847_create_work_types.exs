defmodule RosterApp.Repo.Migrations.CreateWorkTypes do
  use Ecto.Migration

  def change do
    create table(:work_types) do
      add :name, :string
      add :tenant_id, references(:tenants, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:work_types, [:tenant_id])
  end
end
