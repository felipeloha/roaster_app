defmodule RosterApp.ShiftsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `RosterApp.Shifts` context.
  """

  import RosterApp.AccountsFixtures
  alias RosterApp.Repo

  @doc """
  Generate a shift.
  """
  def shift_fixture(attrs \\ %{}) do
    tenant = Repo.insert!(%RosterApp.Tenants.Tenant{name: "Test-Tenant"})
    user = user_fixture(%{tenant_id: tenant.id})
    {:ok, work_type} = work_type_fixture(%{tenant_id: tenant.id})
    {:ok, department} = department_fixture(%{tenant_id: tenant.id})

    {:ok, shift} =
      attrs
      |> Enum.into(%{
        description: "some description",
        end_time: ~U[2025-04-26 06:13:00Z],
        start_time: ~U[2025-04-26 06:12:00Z],
        work_type_id: work_type.id,
        department_id: department.id,
        tenant_id: user.tenant_id
      })
      |> RosterApp.Shifts.create_shift()

    shift
  end
end
