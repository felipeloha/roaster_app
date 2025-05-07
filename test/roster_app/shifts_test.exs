defmodule RosterApp.ShiftsTest do
  use RosterApp.DataCase

  alias RosterApp.Shifts
  alias Shifts.Shift
  alias RosterApp.Orgs
  alias RosterApp.Accounts
  alias RosterApp.Repo
  alias RosterApp.Tenants.Tenant
  import RosterApp.AccountsFixtures
  import RosterApp.ShiftsFixtures

  describe "shifts" do
    import RosterApp.ShiftsFixtures

    @invalid_attrs %{description: nil, start_time: nil, end_time: nil}

    test "list_shifts/0 returns all shifts" do
      shift = shift_fixture()

      [listed] = Shifts.list_shifts(%{role: "manager", tenant_id: shift.tenant_id, user_id: 1})
      assert listed |> Map.drop([:assigned_user]) == shift |> Map.drop([:assigned_user])
    end

    # TODO test list users with roles

    test "get_shift!/1 returns the shift with given id" do
      shift = shift_fixture()

      assert Shifts.get_shift!(shift.id) |> Map.drop([:assigned_user]) ==
               shift |> Map.drop([:assigned_user])
    end

    test "create_shift/1 with valid data creates a shift" do
      {:ok, work_type} = work_type_fixture(%{tenant_id: 1})
      {:ok, department} = department_fixture(%{tenant_id: 1})

      valid_attrs = %{
        description: "some description",
        start_time: ~U[2025-04-26 06:12:00Z],
        end_time: ~U[2025-04-26 06:13:00Z],
        work_type_id: work_type.id,
        department_id: department.id,
        tenant_id: 1
      }

      assert {:ok, %Shift{} = shift} = Shifts.create_shift(valid_attrs)
      assert shift.description == "some description"
      assert shift.start_time == ~U[2025-04-26 06:12:00Z]
      assert shift.end_time == ~U[2025-04-26 06:13:00Z]
    end

    test "invalid create_shift/1 from different tenant_ids" do
      {:ok, work_type} = work_type_fixture(%{tenant_id: 1})
      {:ok, department} = department_fixture(%{tenant_id: 1})

      valid_attrs = %{
        description: "some description",
        start_time: ~U[2025-04-26 06:12:00Z],
        end_time: ~U[2025-04-26 06:13:00Z],
        work_type_id: work_type.id,
        department_id: department.id,
        tenant_id: 1
      }

      assert {:ok, %Shift{} = shift} = Shifts.create_shift(valid_attrs)
      assert shift.description == "some description"
      assert shift.start_time == ~U[2025-04-26 06:12:00Z]
      assert shift.end_time == ~U[2025-04-26 06:13:00Z]
    end

    test "create_shift/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Shifts.create_shift(@invalid_attrs)
    end

    test "update_shift/2 with valid data updates the shift" do
      shift = shift_fixture()

      update_attrs = %{
        description: "some updated description",
        start_time: ~U[2025-04-27 06:12:00Z],
        end_time: ~U[2025-04-27 06:13:00Z]
      }

      assert {:ok, %Shift{} = shift} = Shifts.update_shift(shift, update_attrs)
      assert shift.description == "some updated description"
      assert shift.start_time == ~U[2025-04-27 06:12:00Z]
      assert shift.end_time == ~U[2025-04-27 06:13:00Z]
    end

    test "update_shift/2 with invalid data returns error changeset" do
      shift = shift_fixture()
      assert {:error, %Ecto.Changeset{}} = Shifts.update_shift(shift, @invalid_attrs)

      assert shift |> Map.drop([:assigned_user]) ==
               Shifts.get_shift!(shift.id) |> Map.drop([:assigned_user])
    end

    test "delete_shift/1 deletes the shift" do
      shift = shift_fixture()
      assert {:ok, %Shift{}} = Shifts.delete_shift(shift)
      assert_raise Ecto.NoResultsError, fn -> Shifts.get_shift!(shift.id) end
    end

    test "change_shift/1 returns a shift changeset" do
      shift = shift_fixture()
      assert %Ecto.Changeset{} = Shifts.change_shift(shift)
    end
  end

  describe "create_shift/1" do
    setup do
      # Insert base data
      {:ok, dept} = Orgs.create_department(%{name: "Support", tenant_id: 1})
      {:ok, type} = Orgs.create_work_type(%{name: "Cleaning", tenant_id: 1})

      {:ok, worker} =
        Accounts.register_user(%{
          email: "worker_shift@example.com",
          password: "password1234567894",
          role: "worker",
          tenant_id: 1
        })

      Orgs.assign_user_to_department(worker.id, dept.id)
      Orgs.assign_user_to_work_type(worker.id, type.id)

      %{worker: worker, dept: dept, type: type}
    end

    test "creates a valid shift without assignment", %{dept: dept, type: type} do
      valid_attrs = %{
        start_time: ~U[2025-05-01 09:00:00Z],
        end_time: ~U[2025-05-01 17:00:00Z],
        description: "Cleaning shift",
        department_id: dept.id,
        work_type_id: type.id,
        tenant_id: 1
      }

      assert {:ok, %Shift{} = shift} = Shifts.create_shift(valid_attrs)
      assert shift.description == "Cleaning shift"
      assert shift.assigned_user_id == nil
    end

    test "Tries to create two shifts for same user which overlap between them ", %{
      dept: dept,
      type: type
    } do
      worker_1 =
        create_user_with_department_and_work_type("worker_abc", dept.tenant_id, dept.id, type.id)

      valid_attrs = %{
        start_time: ~U[2025-05-01 09:00:00Z],
        end_time: ~U[2025-05-01 17:00:00Z],
        description: "Cleaning shift",
        department_id: dept.id,
        work_type_id: type.id,
        tenant_id: 1,
        assigned_user_id: worker_1.id
      }

      assert {:ok, %Shift{} = shift} = Shifts.create_shift(valid_attrs)
      assert shift.description == "Cleaning shift"
      assert shift.assigned_user_id == worker_1.id

      {:error, %{errors: errors}} =
        valid_attrs
        |> Map.merge(%{start_time: ~U[2025-05-01 13:00:00Z], end_time: ~U[2025-05-01 21:00:00Z]})
        |> Shifts.create_shift()

      assert errors == [assigned_user_id: {"User is not available for this shift", []}]
    end

    test "fails when end_time is before start_time", %{dept: dept, type: type} do
      invalid_attrs = %{
        start_time: ~U[2025-05-01 17:00:00Z],
        end_time: ~U[2025-05-01 09:00:00Z],
        description: "Backwards shift",
        department_id: dept.id,
        work_type_id: type.id,
        tenant_id: dept.tenant_id
      }

      assert {:error, changeset} = Shifts.create_shift(invalid_attrs)
      assert %{end_time: ["must be after start time"]} = errors_on(changeset)
    end

    test "creates and assigns to a qualified worker", %{worker: worker, dept: dept, type: type} do
      shift_attrs = %{
        start_time: ~U[2025-05-02 08:00:00Z],
        end_time: ~U[2025-05-02 12:00:00Z],
        description: "Morning cleanup",
        department_id: dept.id,
        work_type_id: type.id,
        assigned_user_id: worker.id,
        tenant_id: 1
      }

      assert {:ok, shift} = Shifts.create_shift(shift_attrs)
      assert shift.assigned_user_id == worker.id
    end
  end

  describe "absences with shifts" do
    setup do
      tenant = Repo.insert!(%Tenant{name: "Test-Tenant"})
      {:ok, dept} = Orgs.create_department(%{name: "Logistics", tenant_id: tenant.id})
      {:ok, type} = Orgs.create_work_type(%{name: "Delivery", tenant_id: tenant.id})

      user_1 = create_user_with_department_and_work_type("user_1", tenant.id, dept.id, type.id)
      user_2 = create_user_with_department_and_work_type("user_2", tenant.id, dept.id, type.id)

      %{dept: dept, type: type, user1: user_1, user2: user_2}
    end

    test "eligible_workers_for_shift excludes workers with absences", %{
      dept: dept,
      type: type,
      user1: user1,
      user2: user2
    } do
      # Add absences for user2
      {:ok, _absence} =
        Orgs.create_absences(%{
          user_id: user2.id,
          # Monday
          unavailable_days: [1]
        })

      shift_time = %{
        # Monday
        start_time: ~U[2025-04-28 09:00:00Z],
        end_time: ~U[2025-04-28 17:00:00Z],
        department_id: dept.id,
        work_type_id: type.id,
        tenant_id: user1.tenant_id
      }

      eligible = Shifts.eligible_workers_for_shift(shift_time)
      eligible_ids = Enum.map(eligible, & &1.id)

      # user1 should be eligible
      assert user1.id in eligible_ids

      # user2 should NOT be eligible (absent on Monday)
      refute user2.id in eligible_ids
    end

    test "eligible_workers_for_shift excludes workers with absences (Shift Sunday to Monday)", %{
      dept: dept,
      type: type,
      user1: user1,
      user2: user2
    } do
      # user 3 can not be consider because has a shift on Saturday
      user_3 =
        create_user_with_department_and_work_type("user_3", user2.tenant_id, dept.id, type.id)

      # user 4 can not be consider because has absence on Sundays
      user_4 =
        create_user_with_department_and_work_type("user_4", user2.tenant_id, dept.id, type.id)

      {:ok, _absence} =
        Orgs.create_absences(%{
          user_id: user_4.id,
          # Sunday and Monday
          unavailable_days: [0]
        })

      {:ok, _shift_user_3_saturday} =
        Shifts.create_shift(%{
          start_time: ~U[2025-04-26 07:00:00Z],
          end_time: ~U[2025-04-26 10:00:00Z],
          description: "Shift whole day saturday",
          department_id: dept.id,
          work_type_id: type.id,
          assigned_user_id: user_3.id,
          tenant_id: user_3.tenant_id
        })

      # Add absences for user2
      {:ok, _absence} =
        Orgs.create_absences(%{
          user_id: user2.id,
          # Sunday and Monday
          unavailable_days: [0, 1]
        })

      shift_time = %{
        # Shift Friday to Monday
        start_time: ~U[2025-04-25 23:00:00Z],
        end_time: ~U[2025-04-28 03:00:00Z],
        department_id: dept.id,
        work_type_id: type.id,
        tenant_id: user1.tenant_id
      }

      eligible_ids = shift_time |> Shifts.eligible_workers_for_shift() |> Enum.map(& &1.id)

      assert user_4.id not in eligible_ids
      assert length(eligible_ids) == 1
      assert eligible_ids == [user1.id]

      assert user2.id not in eligible_ids
      assert user_3.id not in eligible_ids
      assert user_4.id not in eligible_ids
    end

    test "eligible_workers_from_shift excludes workers with already assigned shifts", %{
      dept: dept,
      type: type,
      user1: user1,
      user2: user2
    } do
      # Shift 1 assigned to user 1 (Monday to Wednesday shift)
      {:ok, _shift_1} =
        Shifts.create_shift(%{
          start_time: ~U[2025-04-28 09:00:00Z],
          end_time: ~U[2025-04-30 09:00:00Z],
          description: "Shift 1 Monday to Wednesday",
          department_id: dept.id,
          work_type_id: type.id,
          assigned_user_id: user1.id,
          tenant_id: user1.tenant_id
        })

      {:ok, _shift_2} =
        Shifts.create_shift(%{
          start_time: ~U[2025-04-29 09:00:00Z],
          end_time: ~U[2025-04-30 09:00:00Z],
          description: "Shift 2 Tuesday to Wednesday",
          department_id: dept.id,
          work_type_id: type.id,
          assigned_user_id: user2.id,
          tenant_id: user1.tenant_id
        })

      # user 3 with no shifts should be eligible
      user_3 =
        create_user_with_department_and_work_type("user_3", user2.tenant_id, dept.id, type.id)

      user_4 =
        create_user_with_department_and_work_type("user_4", user2.tenant_id, dept.id, type.id)

      user_5 =
        create_user_with_department_and_work_type("user_5", user2.tenant_id, dept.id, type.id)

      # user 4 has a shift in the middle of the new shift
      {:ok, _shift_3} =
        Shifts.create_shift(%{
          start_time: ~U[2025-04-28 05:00:00Z],
          end_time: ~U[2025-04-28 13:00:00Z],
          description: "Shift 3 Monday to Monday",
          department_id: dept.id,
          work_type_id: type.id,
          assigned_user_id: user_4.id,
          tenant_id: user_4.tenant_id
        })

      # user 5 has a shift exact after the end of the shift 2 end date (can be consider)
      {:ok, _shift_5} =
        Shifts.create_shift(%{
          start_time: ~U[2025-04-28 14:01:00Z],
          end_time: ~U[2025-04-29 07:00:00Z],
          description: "Shift 3 Monday to Tuesday",
          department_id: dept.id,
          work_type_id: type.id,
          assigned_user_id: user_5.id,
          tenant_id: user_5.tenant_id
        })

      # Shift 2 assigned to user 1 (Sunday to Monday)
      shift_time = %{
        # Monday
        start_time: ~U[2025-04-27 14:00:00Z],
        end_time: ~U[2025-04-28 14:00:00Z],
        department_id: dept.id,
        work_type_id: type.id,
        tenant_id: user1.tenant_id
      }

      eligible_ids = shift_time |> Shifts.eligible_workers_for_shift() |> Enum.map(& &1.id)

      assert length(eligible_ids) == 3

      # User 1 can not be assigned because its already busy with shift 1
      assert user1.id not in eligible_ids
      assert Enum.sort(eligible_ids) == Enum.sort([user2.id, user_3.id, user_5.id])
    end
  end

  describe "list_shifts/1" do
    test "lists all shifts for managers" do
      tenant = Repo.insert!(%Tenant{name: "Test-Tenant"})
      manager = user_fixture(%{role: "manager", tenant_id: tenant.id})
      worker = user_fixture(%{role: "worker", tenant_id: tenant.id})
      {:ok, department} = department_fixture(%{tenant_id: tenant.id})
      {:ok, work_type} = work_type_fixture(%{tenant_id: tenant.id})

      # Assign worker to department and work type to make them available
      {:ok, _} = Orgs.assign_user_to_department(worker.id, department.id)
      {:ok, _} = Orgs.assign_user_to_work_type(worker.id, work_type.id)

      # Assign manager to department and work type to make them available
      {:ok, _} = Orgs.assign_user_to_department(manager.id, department.id)
      {:ok, _} = Orgs.assign_user_to_work_type(manager.id, work_type.id)

      # Create shifts with different assignments
      {:ok, shift1} =
        Shifts.create_shift(%{
          description: "some description",
          start_time: ~U[2025-04-26 06:12:00Z],
          end_time: ~U[2025-04-26 06:13:00Z],
          work_type_id: work_type.id,
          department_id: department.id,
          tenant_id: tenant.id
        })

      {:ok, shift2} =
        Shifts.create_shift(%{
          description: "some description",
          start_time: ~U[2025-04-26 07:12:00Z],
          end_time: ~U[2025-04-26 07:13:00Z],
          work_type_id: work_type.id,
          department_id: department.id,
          tenant_id: tenant.id,
          assigned_user_id: worker.id
        })

      {:ok, shift3} =
        Shifts.create_shift(%{
          description: "some description",
          start_time: ~U[2025-04-26 08:12:00Z],
          end_time: ~U[2025-04-26 08:13:00Z],
          work_type_id: work_type.id,
          department_id: department.id,
          tenant_id: tenant.id,
          assigned_user_id: manager.id
        })

      shifts = Shifts.list_shifts(%{role: "manager", tenant_id: tenant.id})
      assert length(shifts) == 3

      assert Enum.map(shifts, & &1.id) |> Enum.sort() ==
               [shift1.id, shift2.id, shift3.id] |> Enum.sort()
    end

    test "lists only eligible shifts for workers" do
      tenant = Repo.insert!(%Tenant{name: "Test-Tenant"})
      worker = user_fixture(%{role: "worker", tenant_id: tenant.id})
      {:ok, department} = department_fixture(%{tenant_id: tenant.id})
      {:ok, work_type} = work_type_fixture(%{tenant_id: tenant.id})

      # Assign worker to department and work type
      {:ok, _} = Orgs.assign_user_to_department(worker.id, department.id)
      {:ok, _} = Orgs.assign_user_to_work_type(worker.id, work_type.id)

      # Create shifts
      {:ok, shift1} =
        Shifts.create_shift(%{
          description: "some description",
          start_time: ~U[2025-04-26 06:12:00Z],
          end_time: ~U[2025-04-26 06:13:00Z],
          work_type_id: work_type.id,
          department_id: department.id,
          tenant_id: tenant.id
        })

      {:ok, shift2} =
        Shifts.create_shift(%{
          description: "some description",
          start_time: ~U[2025-04-26 07:12:00Z],
          end_time: ~U[2025-04-26 07:13:00Z],
          work_type_id: work_type.id,
          department_id: department.id,
          tenant_id: tenant.id,
          assigned_user_id: worker.id
        })

      # Create a shift in a different department that worker is not assigned to
      {:ok, department2} = department_fixture(%{tenant_id: tenant.id})

      {:ok, _shift3} =
        Shifts.create_shift(%{
          description: "some description",
          start_time: ~U[2025-04-26 08:12:00Z],
          end_time: ~U[2025-04-26 08:13:00Z],
          work_type_id: work_type.id,
          department_id: department2.id,
          tenant_id: tenant.id
        })

      shifts = Shifts.list_shifts(%{role: "worker", tenant_id: tenant.id, id: worker.id})
      assert length(shifts) == 2
      assert Enum.map(shifts, & &1.id) |> Enum.sort() == [shift1.id, shift2.id] |> Enum.sort()
    end

    test "filters out shifts for departments worker is not assigned to" do
      tenant = Repo.insert!(%Tenant{name: "Test-Tenant"})
      worker = user_fixture(%{role: "worker", tenant_id: tenant.id})
      {:ok, department1} = department_fixture(%{tenant_id: tenant.id})
      {:ok, department2} = department_fixture(%{tenant_id: tenant.id})
      {:ok, work_type} = work_type_fixture(%{tenant_id: tenant.id})

      # Assign worker to only department1
      {:ok, _} = Orgs.assign_user_to_department(worker.id, department1.id)
      {:ok, _} = Orgs.assign_user_to_work_type(worker.id, work_type.id)

      # Create shifts in both departments
      {:ok, shift1} =
        Shifts.create_shift(%{
          description: "some description",
          start_time: ~U[2025-04-26 06:12:00Z],
          end_time: ~U[2025-04-26 06:13:00Z],
          work_type_id: work_type.id,
          department_id: department1.id,
          tenant_id: tenant.id
        })

      {:ok, _shift2} =
        Shifts.create_shift(%{
          description: "some description",
          start_time: ~U[2025-04-26 07:12:00Z],
          end_time: ~U[2025-04-26 07:13:00Z],
          work_type_id: work_type.id,
          department_id: department2.id,
          tenant_id: tenant.id
        })

      shifts = Shifts.list_shifts(%{role: "worker", tenant_id: tenant.id, id: worker.id})
      assert length(shifts) == 1
      assert hd(shifts).id == shift1.id
    end

    test "filters out shifts for work types worker is not qualified for" do
      tenant = Repo.insert!(%Tenant{name: "Test-Tenant"})
      worker = user_fixture(%{role: "worker", tenant_id: tenant.id})
      {:ok, department} = department_fixture(%{tenant_id: tenant.id})
      {:ok, work_type1} = work_type_fixture(%{tenant_id: tenant.id})
      {:ok, work_type2} = work_type_fixture(%{tenant_id: tenant.id})

      # Assign worker to only work_type1
      {:ok, _} = Orgs.assign_user_to_department(worker.id, department.id)
      {:ok, _} = Orgs.assign_user_to_work_type(worker.id, work_type1.id)

      # Create shifts for both work types
      {:ok, shift1} =
        Shifts.create_shift(%{
          description: "some description",
          start_time: ~U[2025-04-26 06:12:00Z],
          end_time: ~U[2025-04-26 06:13:00Z],
          work_type_id: work_type1.id,
          department_id: department.id,
          tenant_id: tenant.id
        })

      {:ok, _shift2} =
        Shifts.create_shift(%{
          description: "some description",
          start_time: ~U[2025-04-26 07:12:00Z],
          end_time: ~U[2025-04-26 07:13:00Z],
          work_type_id: work_type2.id,
          department_id: department.id,
          tenant_id: tenant.id
        })

      shifts = Shifts.list_shifts(%{role: "worker", tenant_id: tenant.id, id: worker.id})
      assert length(shifts) == 1
      assert hd(shifts).id == shift1.id
    end

    test "filters out shifts that overlap with worker's absences" do
      tenant = Repo.insert!(%Tenant{name: "Test-Tenant"})
      worker = user_fixture(%{role: "worker", tenant_id: tenant.id})
      {:ok, department} = department_fixture(%{tenant_id: tenant.id})
      {:ok, work_type} = work_type_fixture(%{tenant_id: tenant.id})

      # Assign worker to department and work type
      {:ok, _} = Orgs.assign_user_to_department(worker.id, department.id)
      {:ok, _} = Orgs.assign_user_to_work_type(worker.id, work_type.id)

      # Create an absence for Monday (1)
      {:ok, _} =
        Orgs.create_absences(%{
          user_id: worker.id,
          tenant_id: tenant.id,
          unavailable_days: [1]
        })

      # Create shifts
      {:ok, _monday_shift} =
        Shifts.create_shift(%{
          description: "some description",
          start_time: ~U[2024-04-01 09:00:00Z],
          end_time: ~U[2024-04-01 17:00:00Z],
          work_type_id: work_type.id,
          department_id: department.id,
          tenant_id: tenant.id
        })

      {:ok, tuesday_shift} =
        Shifts.create_shift(%{
          description: "some description",
          start_time: ~U[2024-04-02 09:00:00Z],
          end_time: ~U[2024-04-02 17:00:00Z],
          work_type_id: work_type.id,
          department_id: department.id,
          tenant_id: tenant.id
        })

      shifts = Shifts.list_shifts(%{role: "worker", tenant_id: tenant.id, id: worker.id})
      assert length(shifts) == 1
      assert hd(shifts).id == tuesday_shift.id
    end

    test "filters out shifts that overlap with worker's other assigned shifts" do
      tenant = Repo.insert!(%Tenant{name: "Test-Tenant"})
      worker = user_fixture(%{role: "worker", tenant_id: tenant.id})
      {:ok, department} = department_fixture(%{tenant_id: tenant.id})
      {:ok, work_type} = work_type_fixture(%{tenant_id: tenant.id})

      # Assign worker to department and work type
      {:ok, _} = Orgs.assign_user_to_department(worker.id, department.id)
      {:ok, _} = Orgs.assign_user_to_work_type(worker.id, work_type.id)

      # Create an existing shift for the worker
      {:ok, existing_shift} =
        Shifts.create_shift(%{
          description: "some description",
          start_time: ~U[2024-04-01 09:00:00Z],
          end_time: ~U[2024-04-01 17:00:00Z],
          work_type_id: work_type.id,
          department_id: department.id,
          tenant_id: tenant.id,
          assigned_user_id: worker.id
        })

      # Create overlapping shifts
      {:ok, _overlapping_shift} =
        Shifts.create_shift(%{
          description: "some description",
          start_time: ~U[2024-04-01 10:00:00Z],
          end_time: ~U[2024-04-01 16:00:00Z],
          work_type_id: work_type.id,
          department_id: department.id,
          tenant_id: tenant.id
        })

      {:ok, non_overlapping_shift} =
        Shifts.create_shift(%{
          description: "some description",
          start_time: ~U[2024-04-02 09:00:00Z],
          end_time: ~U[2024-04-02 17:00:00Z],
          work_type_id: work_type.id,
          department_id: department.id,
          tenant_id: tenant.id
        })

      shifts = Shifts.list_shifts(%{role: "worker", tenant_id: tenant.id, id: worker.id})
      assert length(shifts) == 2
      shift_ids = Enum.map(shifts, & &1.id) |> Enum.sort()
      assert shift_ids == [existing_shift.id, non_overlapping_shift.id] |> Enum.sort()
    end
  end

  defp create_user_with_department_and_work_type(prefix, tenant_id, department_id, work_type_id) do
    {:ok, user} =
      Accounts.register_user(%{
        email: "#{prefix}@example.com",
        password: "#{prefix}_password",
        role: "worker",
        tenant_id: tenant_id
      })

    Orgs.assign_user_to_department(user.id, department_id)
    Orgs.assign_user_to_work_type(user.id, work_type_id)
    user
  end
end
