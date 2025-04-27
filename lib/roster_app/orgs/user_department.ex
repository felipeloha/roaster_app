defmodule RosterApp.Orgs.UserDepartment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_departments" do
    field :user_id, :id
    field :department_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user_department, attrs) do
    user_department
    |> cast(attrs, [])
    |> validate_required([])
  end
end
