defmodule RosterApp.Orgs do
  import Ecto.Query, warn: false
  alias RosterApp.Repo

  alias RosterApp.Orgs.{Department, WorkType, UserDepartment, UserQualification}
  alias RosterApp.Accounts.User

  def day_map() do
    %{
      1 => "Monday",
      2 => "Tuesday",
      3 => "Wednesday",
      4 => "Thursday",
      5 => "Friday",
      6 => "Saturday",
      0 => "Sunday"
    }
  end

  def day_map_as_tuples() do
    Enum.map(day_map(), fn {key, value} -> {value, key} end)
  end

  def list_work_types(tenant_id) do
    Repo.all(from wt in WorkType, where: wt.tenant_id == ^tenant_id)
  end

  def list_departments(tenant_id) do
    Repo.all(from d in Department, where: d.tenant_id == ^tenant_id)
  end

  def create_department(attrs \\ %{}) do
    %Department{}
    |> Department.changeset(attrs)
    |> Repo.insert()
  end

  def create_work_type(attrs \\ %{}) do
    %WorkType{}
    |> WorkType.changeset(attrs)
    |> Repo.insert()
  end

  # Function to assign a user to a department
  def assign_user_to_department(user_id, department_id) do
    # Assuming users have a `department_id` field or a many-to-many relationship
    case Repo.get(User, user_id) do
      nil ->
        {:error, "User not found"}

      _user ->
        %UserDepartment{}
        |> UserDepartment.changeset(%{user_id: user_id, department_id: department_id})
        |> Repo.insert()
    end
  end

  # Function to assign a user to a work type
  def assign_user_to_work_type(user_id, work_type_id) do
    case Repo.get(User, user_id) do
      nil ->
        {:error, "User not found"}

      _user ->
        %UserQualification{}
        |> UserQualification.changeset(%{user_id: user_id, work_type_id: work_type_id})
        |> Repo.insert()
    end
  end

  alias RosterApp.Orgs.Absences

  @doc """
  Returns the list of absences.

  ## Examples

      iex> list_absences()
      [%Absences{}, ...]

  """
  def list_absences(user_id) do
    Repo.all(from a in Absences, where: a.user_id == ^user_id)
  end

  @doc """
  Gets a single absences.

  Raises `Ecto.NoResultsError` if the Absences does not exist.

  ## Examples

      iex> get_absences!(123)
      %Absences{}

      iex> get_absences!(456)
      ** (Ecto.NoResultsError)

  """
  def get_absences!(id), do: Repo.get!(Absences, id)

  @doc """
  Creates a absences.

  ## Examples

      iex> create_absences(%{field: value})
      {:ok, %Absences{}}

      iex> create_absences(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_absences(attrs \\ %{}) do
    %Absences{}
    |> Absences.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a absences.

  ## Examples

      iex> update_absences(absences, %{field: new_value})
      {:ok, %Absences{}}

      iex> update_absences(absences, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_absences(%Absences{} = absences, attrs) do
    absences
    |> Absences.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a absences.

  ## Examples

      iex> delete_absences(absences)
      {:ok, %Absences{}}

      iex> delete_absences(absences)
      {:error, %Ecto.Changeset{}}

  """
  def delete_absences(%Absences{} = absences) do
    Repo.delete(absences)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking absences changes.

  ## Examples

      iex> change_absences(absences)
      %Ecto.Changeset{data: %Absences{}}

  """
  def change_absences(%Absences{} = absences, attrs \\ %{}) do
    Absences.changeset(absences, attrs)
  end
end
