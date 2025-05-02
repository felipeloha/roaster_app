defmodule RosterApp.Orgs.WorkType do
  use Ecto.Schema
  import Ecto.Changeset

  schema "work_types" do
    field :name, :string
    belongs_to :tenant, RosterApp.Tenants.Tenant

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(work_type, attrs) do
    work_type
    |> cast(attrs, [:name, :tenant_id])
    |> validate_required([:name, :tenant_id])
  end
end
