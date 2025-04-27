defmodule RosterApp.ShiftsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `RosterApp.Shifts` context.
  """

  import RosterApp.AccountsFixtures

  @doc """
  Generate a shift.
  """
  def shift_fixture(attrs \\ %{}) do
    {:ok, work_type} = work_type_fixture()
    {:ok, department} = department_fixture()

    {:ok, shift} =
      attrs
      |> Enum.into(%{
        description: "some description",
        end_time: ~U[2025-04-26 06:13:00Z],
        start_time: ~U[2025-04-26 06:12:00Z],
        work_type_id: work_type.id,
        department_id: department.id
      })
      |> RosterApp.Shifts.create_shift()

    shift
  end
end
