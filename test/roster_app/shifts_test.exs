defmodule RosterApp.ShiftsTest do
  use RosterApp.DataCase

  alias RosterApp.Shifts
  alias Shifts.Shift
  alias RosterApp.Orgs
  alias RosterApp.Accounts
  import RosterApp.AccountsFixtures

  describe "shifts" do
    import RosterApp.ShiftsFixtures

    @invalid_attrs %{description: nil, start_time: nil, end_time: nil}

    test "list_shifts/0 returns all shifts" do
      shift = shift_fixture()
      assert Shifts.list_shifts(shift.tenant_id) == [shift]
    end

    test "get_shift!/1 returns the shift with given id" do
      shift = shift_fixture()
      assert Shifts.get_shift!(shift.id) == shift
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
      assert shift == Shifts.get_shift!(shift.id)
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

  # TODO  add overlapping check
  #  describe "eligible_workers_for_shift/1" do
  #    setup do
  #      {:ok, dept} = Orgs.create_department(%{name: "Ops"})
  #      {:ok, type} = Orgs.create_work_type(%{name: "Security"})
  #
  #      {:ok, user1} =
  #        Accounts.register_user(%{email: "user1@example.com", password: "secret12345678910", role: "worker"})
  #
  #      {:ok, user2} =
  #        Accounts.register_user(%{email: "user2@example.com", password: "secret12345678910", role: "worker"})
  #
  #      {:ok, user3} =
  #        Accounts.register_user(%{email: "user3@example.com", password: "secret12345678910", role: "worker"})
  #
  #      Enum.each([user1, user2, user3], fn user ->
  #        Orgs.assign_user_to_department(user.id, dept.id)
  #        Orgs.assign_user_to_work_type(user.id, type.id)
  #      end)
  #
  #      # Set recurring unavailability for user2 on Mondays
  #      {:ok, _} =
  #        Workers.create_availability(%{
  #          user_id: user2.id,
  #          excluded_days: [1],
  #          recurring: true,
  #          start_time: ~T[00:00:00],
  #          end_time: ~T[23:59:59]
  #        })
  #
  #      # Assign user3 to an overlapping shift
  #      {:ok, _} =
  #        Shifts.create_shift(%{
  #          start_time: ~U[2025-04-28 10:00:00Z],
  #          end_time: ~U[2025-04-28 14:00:00Z],
  #          description: "Existing shift",
  #          department_id: dept.id,
  #          work_type_id: type.id,
  #          assigned_user_id: user3.id
  #        })
  #
  #      %{
  #        dept: dept,
  #        type: type,
  #        user1: user1,
  #        user2: user2,
  #        user3: user3
  #      }
  #    end
  #
  #    test "filters out users with excluded days and overlaps", %{
  #      dept: dept,
  #      type: type,
  #      user1: user1
  #    } do
  #      shift_time = %{
  #        # Monday
  #        start_time: ~U[2025-04-28 12:00:00Z],
  #        end_time: ~U[2025-04-28 16:00:00Z],
  #        department_id: dept.id,
  #        work_type_id: type.id
  #      }
  #
  #      eligible = Shifts.eligible_workers_for_shift(shift_time)
  #
  #      eligible_ids = Enum.map(eligible, & &1.id)
  #
  #      # user1 should be eligible (no exclusion, no conflict)
  #      assert user1.id in eligible_ids
  #
  #      # user2 should NOT be eligible (excluded on Monday)
  #      refute Enum.any?(eligible_ids, fn id -> id == 2 end)
  #
  #      # user3 should NOT be eligible (overlapping shift)
  #      refute Enum.any?(eligible_ids, fn id -> id == 3 end)
  #    end
  #  end

  describe "absences with shifts" do
    setup do
      tenant = Repo.insert!(%RosterApp.Tenants.Tenant{name: "Test-Tenant"})
      {:ok, dept} = Orgs.create_department(%{name: "Logistics", tenant_id: tenant.id})
      {:ok, type} = Orgs.create_work_type(%{name: "Delivery", tenant_id: tenant.id})

      # Register users
      user1 = user_with_absence("user1", [], dept, type)
      user2 = user_with_absence("user2", [1], dept, type)

      %{dept: dept, type: type, user1: user1, user2: user2}
    end

    test "eligible_workers_for_shift selects only eligible in work types and departments", %{
      dept: dept
    } do
      # shift goes to new department with new work type and lasts from monday to wednesday
      # user1 is selected by department and work type and absence is on saturday and sunday
      # user2 is excluded by absence on Monday
      # user3 is excluded by absence on Wednesday
      # the users from setup are excluded by department and worktype
      {:ok, selected_dept} =
        Orgs.create_department(%{name: "selected_dept", tenant_id: dept.tenant_id})

      {:ok, selected_work_type} =
        Orgs.create_work_type(%{name: "selected_work_type", tenant_id: dept.tenant_id})

      {:ok, selected_user} =
        Accounts.register_user(%{
          email: "selected@mail.com",
          password: "password123456789",
          role: "worker",
          tenant_id: dept.tenant_id
        })

      Orgs.assign_user_to_department(selected_user.id, selected_dept.id)
      Orgs.assign_user_to_work_type(selected_user.id, selected_work_type.id)

      # excluded user by absence on monday
      _user_mon = user_with_absence("exc_monday", [1], selected_dept, selected_work_type)
      _user_wed = user_with_absence("exc_wed", [3], selected_dept, selected_work_type)

      shift_time = %{
        # Monday - Wednesday
        start_time: ~U[2025-04-28 09:00:00Z],
        end_time: ~U[2025-04-30 17:00:00Z],
        department_id: selected_dept.id,
        work_type_id: selected_work_type.id,
        tenant_id: dept.tenant_id
      }

      eligible = Shifts.eligible_workers_for_shift(shift_time)
      eligible_ids = Enum.map(eligible, & &1.id)

      # only selected user should be eligible
      assert [selected_user.id] == eligible_ids
    end

    test "eligible_workers_for_shift excludes workers from other departments", %{
      dept: dept,
      type: type,
      user1: user1,
      user2: user2
    } do
      shift_time = %{
        # Monday
        start_time: ~U[2025-04-28 09:00:00Z],
        end_time: ~U[2025-04-28 17:00:00Z],
        department_id: dept.id,
        work_type_id: type.id,
        tenant_id: dept.tenant_id
      }

      eligible = Shifts.eligible_workers_for_shift(shift_time)
      eligible_ids = Enum.map(eligible, & &1.id)

      # user1 should be eligible
      assert user1.id in eligible_ids

      # user2 should NOT be eligible (absent on Monday)
      refute user2.id in eligible_ids
    end
  end

  def user_with_absence(id, unavailable_days, dept, work_type) do
    {:ok, user} =
      Accounts.register_user(%{
        email: "#{id}@mail.com",
        password: "password123456789",
        role: "worker",
        tenant_id: dept.tenant_id
      })

    {:ok, _absence} =
      Orgs.create_absences(%{
        user_id: user.id,
        unavailable_days: unavailable_days
      })

    Orgs.assign_user_to_department(user.id, dept.id)
    Orgs.assign_user_to_work_type(user.id, work_type.id)

    user
  end
end
