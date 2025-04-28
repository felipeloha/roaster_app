defmodule RosterApp.Orgs.UserQualification do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_qualifications" do
    # field :user_id, :id
    # field :work_type_id, :id

    belongs_to :user, RosterApp.Accounts.User
    belongs_to :work_type, RosterApp.Orgs.WorkType

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user_qualification, attrs) do
    user_qualification
    |> cast(attrs, [:user_id, :work_type_id])
    |> validate_required([:user_id, :work_type_id])
  end
end
