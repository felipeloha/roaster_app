defmodule RosterApp.Repo.Migrations.CreateDepartments do
  use Ecto.Migration

  def change do
    create table(:departments) do
      add :name, :string
      add :tenant_id, references(:tenants, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:departments, [:tenant_id])
  end
end
