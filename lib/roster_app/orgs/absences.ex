defmodule RosterApp.Orgs.Absences do
  use Ecto.Schema
  import Ecto.Changeset

  schema "absences" do
    field :unavailable_days, {:array, :integer}
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(absences, attrs) do
    absences
    |> cast(attrs, [:unavailable_days, :user_id])
    # TODO validate and pass from liveview
    # |> validate_required([:unavailable_days, :user_id])
    |> update_change(:unavailable_days, fn days -> Enum.uniq(days) end)
  end
end
