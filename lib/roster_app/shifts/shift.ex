defmodule RosterApp.Shifts.Shift do
  use Ecto.Schema
  import Ecto.Changeset

  schema "shifts" do
    field :start_time, :utc_datetime
    field :end_time, :utc_datetime
    field :description, :string

    belongs_to :work_type, RosterApp.Orgs.WorkType
    belongs_to :department, RosterApp.Orgs.Department
    belongs_to :assigned_user, RosterApp.Accounts.User, foreign_key: :assigned_user_id

    timestamps()
  end

  def changeset(shift, attrs) do
    shift
    |> cast(attrs, [
      :start_time,
      :end_time,
      :description,
      :work_type_id,
      :department_id,
      :assigned_user_id
    ])
    |> validate_required([:start_time, :end_time, :description, :work_type_id, :department_id])
    |> validate_change(:end_time, fn :end_time, end_time ->
      start_time = Map.get(attrs, :start_time)

      if start_time && DateTime.compare(end_time, start_time) != :gt do
        [end_time: "must be after start time"]
      else
        []
      end
    end)
  end
end
