defmodule RosterApp.Orgs.Department do
  use Ecto.Schema
  import Ecto.Changeset

  schema "departments" do
    field :name, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(department, attrs) do
    department
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
