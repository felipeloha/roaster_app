defmodule RosterApp.Orgs do
  import Ecto.Query, warn: false
  alias RosterApp.Repo

  alias RosterApp.Orgs.{Department, WorkType, UserDepartment, UserQualification}
  alias RosterApp.Accounts.User

  def list_work_types() do
    Repo.all(WorkType)
  end

  def list_departments() do
    Repo.all(Department)
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
end
