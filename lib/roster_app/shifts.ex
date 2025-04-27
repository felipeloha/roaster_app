defmodule RosterApp.Shifts do
  @moduledoc """
  The Shifts context.
  """

  import Ecto.Query, warn: false
  alias RosterApp.Repo

  alias RosterApp.Shifts.Shift
  alias RosterApp.Accounts.User

  @doc """
  Returns the list of shifts.

  ## Examples

      iex> list_shifts()
      [%Shift{}, ...]

  """
  def list_shifts do
    Repo.all(Shift)
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
  def get_shift!(id), do: Repo.get!(Shift, id)

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

  def eligible_workers_for_shift(%{
        start_time: start_time,
        end_time: _end_time,
        department_id: dept_id,
        work_type_id: type_id
      }) do
    from(u in User,
      as: :u,
      join: d in assoc(u, :departments),
      join: w in assoc(u, :work_types),
      where: d.id == ^dept_id and w.id == ^type_id,
      where:
        not exists(
          from a in RosterApp.Workers.Availability,
            where:
              a.user_id == parent_as(:u).id and
                fragment(
                  "? = ANY(?)",
                  fragment("EXTRACT(DOW FROM ?)", ^start_time),
                  a.excluded_days
                ),
            select: 1
        )
    )
    |> Repo.all()
  end
end
