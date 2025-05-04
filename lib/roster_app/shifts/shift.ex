defmodule RosterApp.Shifts.Shift do
  use Ecto.Schema
  import Ecto.Changeset
  alias RosterApp.Repo

  schema "shifts" do
    field :start_time, :utc_datetime
    field :end_time, :utc_datetime
    field :description, :string

    belongs_to :work_type, RosterApp.Orgs.WorkType, foreign_key: :work_type_id
    belongs_to :department, RosterApp.Orgs.Department, foreign_key: :department_id
    belongs_to :assigned_user, RosterApp.Accounts.User, foreign_key: :assigned_user_id
    belongs_to :tenant, RosterApp.Tenants.Tenant, foreign_key: :tenant_id

    timestamps()
  end

  def changeset(shift, attrs) do
    changeset =
      shift
      |> cast(attrs, [
        :start_time,
        :end_time,
        :description,
        :work_type_id,
        :department_id,
        :assigned_user_id,
        :tenant_id
      ])
      |> validate_required([
        :start_time,
        :end_time,
        :description,
        :work_type_id,
        :department_id,
        :tenant_id
      ])

    changeset
    |> validate_change(:department_id, fn :department_id, department_id ->
      validate_tenant_id(
        RosterApp.Orgs.Department,
        changeset,
        department_id,
        :department_id
      )
    end)
    |> validate_change(:work_type, fn :work_type, work_type ->
      validate_tenant_id(
        RosterApp.Orgs.WorkType,
        changeset,
        work_type,
        :work_type
      )
    end)
    |> validate_change(:assigned_user_id, fn :assigned_user_id, assigned_user_id ->
      validate_tenant_id(
        RosterApp.Accounts.User,
        changeset,
        assigned_user_id,
        :assigned_user_id
      )
    end)
    |> validate_change(:end_time, fn :end_time, end_time ->
      start_time = get_field(changeset, :start_time)

      if not is_nil(start_time) && DateTime.compare(end_time, start_time) != :gt do
        [end_time: "must be after start time"]
      else
        []
      end
    end)
  end

  def validate_tenant_id(_schema, _changeset, nil, _), do: []

  def validate_tenant_id(schema, changeset, attribute, attr_name) do
    entity = Repo.get_by!(schema, id: attribute)
    entity_tenant_id = entity.tenant_id
    shift_tenant_id = get_field(changeset, :tenant_id)

    if entity_tenant_id != shift_tenant_id do
      [
        {attr_name,
         "#{attr_name} must be from the same tenant as shift. Entity tenant id '#{entity_tenant_id}' != shift tenant id '#{shift_tenant_id}'"}
      ]
    else
      []
    end
  end
end
