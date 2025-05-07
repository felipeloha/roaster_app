defmodule RosterApp.Shifts do
  @moduledoc """
  The Shifts context.
  """

  import Ecto.Query, warn: false
  alias Ecto.Changeset
  alias RosterApp.Repo
  alias RosterApp.Shifts.Shift
  alias RosterApp.Accounts.User

  @total_days_in_week 7
  @doc """
  Returns the list of shifts.

  ## Examples

      iex> list_shifts()
      [%Shift{}, ...]

  """
  def list_shifts(%{role: "worker", tenant_id: tenant_id, id: user_id}) do
    # Get user's departments and work types
    user =
      Repo.get!(User, user_id)
      |> Repo.preload([:departments, :work_types])

    user_departments = Enum.map(user.departments, & &1.id)
    user_work_types = Enum.map(user.work_types, & &1.id)

    # TODO: Refactor this query to reuse the logic from get_eligible_workers_base_query
    # The following conditions are duplicated:
    # 1. Checking for absences overlap
    # 2. Checking for overlapping shifts
    # Consider extracting these into a shared function that can be used by both
    # list_shifts and get_eligible_workers_base_query
    Repo.all(
      from s in Shift,
        as: :shift,
        where: s.tenant_id == ^tenant_id,
        where: is_nil(s.assigned_user_id) or s.assigned_user_id == ^user_id,
        where: s.department_id in ^user_departments,
        where: s.work_type_id in ^user_work_types,
        # Exclude shifts that overlap with user's absences
        where:
          not exists(
            from a in RosterApp.Orgs.Absences,
              join:
                d in fragment(
                  "SELECT generate_series(?, ?, '1 day'::interval) as day",
                  parent_as(:shift).start_time,
                  parent_as(:shift).end_time
                ),
              where:
                a.user_id == ^user_id and
                  fragment("? && array[extract(dow from ?)::integer]", a.unavailable_days, d.day),
              select: 1
          ),
        # Exclude shifts that overlap with user's other assigned shifts
        where:
          not exists(
            from os in Shift,
              where:
                os.assigned_user_id == ^user_id and
                  os.id != parent_as(:shift).id and
                  os.end_time >= parent_as(:shift).start_time and
                  os.start_time <= parent_as(:shift).end_time,
              select: 1
          ),
        order_by: [desc: fragment("assigned_user_id IS NULL"), asc: s.start_time],
        preload: [:assigned_user]
    )
  end

  def list_shifts(%{role: _, tenant_id: tenant_id}) do
    Repo.all(
      from s in Shift,
        where: s.tenant_id == ^tenant_id,
        order_by: [desc: fragment("assigned_user_id IS NULL"), asc: s.start_time],
        preload: [:assigned_user]
    )
  end

  @doc """
  Gets a single shift.

  Raises `Ecto.NoResultsError` if the Shift does not exist.

  ## Examples

      iex> get_shift!(123)
      %Shift{}

      iex> get_shift!(456)
      ** (Ecto.NoResultsError)

  """
  def get_shift!(id), do: Repo.get!(Shift, id) |> Repo.preload(:assigned_user)

  @doc """
  Creates a shift.

  ## Examples

      iex> create_shift(%{field: value})
      {:ok, %Shift{}}

      iex> create_shift(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_shift(attrs \\ %{}) do
    %Shift{}
    |> Shift.changeset(attrs)
    |> validate_overlapping_user_shifts()
    |> Repo.insert()
  end

  @doc """
  Updates a shift.

  ## Examples

      iex> update_shift(shift, %{field: new_value})
      {:ok, %Shift{}}

      iex> update_shift(shift, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_shift(%Shift{} = shift, attrs) do
    shift
    |> Shift.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a shift.

  ## Examples

      iex> delete_shift(shift)
      {:ok, %Shift{}}

      iex> delete_shift(shift)
      {:error, %Ecto.Changeset{}}

  """
  def delete_shift(%Shift{} = shift) do
    Repo.delete(shift)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking shift changes.

  ## Examples

      iex> change_shift(shift)
      %Ecto.Changeset{data: %Shift{}}

  """
  def change_shift(%Shift{} = shift, attrs \\ %{}) do
    Shift.changeset(shift, attrs)
  end

  def days_of_week_between(start_date, end_date) do
    start_date
    |> Date.range(end_date)
    # Map day of the weeks to Postgres values (0-6)
    |> Enum.map(&(&1 |> Date.day_of_week() |> rem(@total_days_in_week)))
  end

  def eligible_workers_for_shift(%{
        tenant_id: tenant_id,
        start_time: start_time,
        end_time: end_time,
        department_id: dept_id,
        work_type_id: type_id
      }) do
    # TODO implement timezone awareness

    tenant_id
    |> get_eligible_workers_base_query(dept_id, type_id, start_time, end_time)
    |> Repo.all()
  end

  defp user_available_for_shift?(user_id, tenant_id, dept_id, type_id, start_time, end_time) do
    tenant_id
    |> get_eligible_workers_base_query(dept_id, type_id, start_time, end_time)
    |> where([user], user.id == ^user_id)
    |> limit(1)
    |> Repo.one()
    |> case do
      nil -> false
      _ -> true
    end
  end

  defp validate_overlapping_user_shifts(%{valid?: false} = changeset), do: changeset

  defp validate_overlapping_user_shifts(changeset) do
    assigned_user_id = Changeset.get_field(changeset, :assigned_user_id)

    if assigned_user_id do
      validate_overlapping_user_shifts_impl(changeset, assigned_user_id)
    else
      changeset
    end
  end

  defp validate_overlapping_user_shifts_impl(changeset, assigned_user_id) do
    tenant_id = Changeset.get_field(changeset, :tenant_id)
    start_time = Changeset.get_field(changeset, :start_time)
    end_time = Changeset.get_field(changeset, :end_time)
    department_id = Changeset.get_field(changeset, :department_id)
    work_type_id = Changeset.get_field(changeset, :work_type_id)

    %{
      tenant_id: tenant_id,
      start_time: start_time,
      end_time: end_time,
      department_id: department_id,
      work_type_id: work_type_id
    }

    assigned_user_id
    |> user_available_for_shift?(tenant_id, department_id, work_type_id, start_time, end_time)
    |> if do
      changeset
    else
      Changeset.add_error(changeset, :assigned_user_id, "User is not available for this shift")
    end
  end

  # refactoring this big query with bindings into smaller functions would make a mess with the parent_as binding
  defp get_eligible_workers_base_query(tenant_id, dept_id, type_id, start_time, end_time) do
    shift_days = days_of_week_between(start_time, end_time)

    from(user in User, as: :user)
    |> join(:inner, [user], d in assoc(user, :departments), as: :department)
    |> join(:inner, [user], w in assoc(user, :work_types), as: :work_type)
    |> where(
      [user, department: department, work_type: work_type],
      user.tenant_id == ^tenant_id and department.id == ^dept_id and work_type.id == ^type_id
    )
    # Should exclude users which absences overlap with the current shift
    |> where(
      [user],
      not exists(
        from a in RosterApp.Orgs.Absences,
          where:
            a.user_id == parent_as(:user).id and
              fragment("? && ?", a.unavailable_days, ^shift_days),
          select: 1
      )
    )
    # Should exclude users that are already assigned to a shift that overlaps current shift
    |> where(
      [user],
      not exists(
        from shift in Shift,
          where:
            shift.assigned_user_id == parent_as(:user).id and
              shift.end_time >= ^start_time and shift.start_time <= ^end_time,
          select: 1
      )
    )
  end
end
