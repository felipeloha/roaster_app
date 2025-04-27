defmodule RosterApp.Orgs.WorkType do
  use Ecto.Schema
  import Ecto.Changeset

  schema "work_types" do
    field :name, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(work_type, attrs) do
    work_type
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
