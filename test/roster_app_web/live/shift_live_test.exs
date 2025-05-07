defmodule RosterAppWeb.ShiftLiveTest do
  use RosterAppWeb.ConnCase

  import Phoenix.LiveViewTest
  import RosterApp.ShiftsFixtures
  import RosterApp.AccountsFixtures

  @create_attrs %{
    description: "some description",
    start_time: "2025-04-26T06:12:00Z",
    end_time: "2025-04-27T06:12:00Z"
  }
  @update_attrs %{
    description: "some updated description",
    start_time: "2025-04-27T06:12:00Z",
    end_time: "2025-04-28T06:12:00Z"
  }
  @invalid_attrs %{
    description: nil,
    start_time: "2025-04-27T06:12:00Z",
    end_time: "2025-04-27T06:12:00Z"
  }

  describe "Index" do
    setup %{conn: conn} do
      user = user_fixture(%{role: "manager", email: "shift_man@mail.com"})
      shift = shift_fixture(%{user: user, tenant_id: user.tenant_id})
      %{conn: log_in_user(conn, user), user: user, shift: shift}
    end

    test "lists all shifts", %{conn: conn, shift: shift} do
      {:ok, _index_live, html} = live(conn, ~p"/shifts")

      assert html =~ "Listing Shifts"
      assert html =~ shift.description
    end

    test "saves new shift", %{conn: conn, user: user} do
      {:ok, work_type} = work_type_fixture(%{tenant_id: user.tenant_id})
      {:ok, department} = department_fixture(%{tenant_id: user.tenant_id})

      {:ok, index_live, _html} = live(conn, ~p"/shifts")

      assert index_live |> element("a", "New Shift") |> render_click() =~
               "New Shift"

      assert_patch(index_live, ~p"/shifts/new")

      assert index_live
             |> form("#shift-form", shift: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#shift-form",
               shift:
                 Enum.into(
                   %{work_type_id: work_type.id, department_id: department.id},
                   @create_attrs
                 )
             )
             |> render_submit()

      assert_patch(index_live, ~p"/shifts")

      html = render(index_live)
      assert html =~ "Shift created successfully"
      assert html =~ "some description"
    end

    test "updates shift in listing", %{conn: conn, shift: shift} do
      {:ok, index_live, _html} = live(conn, ~p"/shifts")

      assert index_live
             |> element("#shifts-#{shift.id} a", "Edit")
             |> render_click() =~ "Edit Shift"

      assert_patch(index_live, ~p"/shifts/#{shift}/edit")

      assert index_live
             |> form("#shift-form", shift: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#shift-form", shift: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/shifts")

      html = render(index_live)
      assert html =~ "Shift updated successfully"
      assert html =~ "some updated description"
    end

    test "deletes shift in listing", %{conn: conn, shift: shift} do
      {:ok, index_live, _html} = live(conn, ~p"/shifts")

      assert index_live |> element("#shifts-#{shift.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#shifts-#{shift.id}")
    end
  end

  describe "Real-time updates" do
    setup %{conn: conn} do
      # Create two users in the same tenant
      manager = user_fixture(%{role: "manager", email: "manager@test.com"})

      worker =
        user_fixture(%{role: "worker", email: "worker@test.com", tenant_id: manager.tenant_id})

      # Create work type and department for new shifts
      {:ok, work_type} = work_type_fixture(%{tenant_id: manager.tenant_id})
      {:ok, department} = department_fixture(%{tenant_id: manager.tenant_id})

      # Add work type and department qualifications to the worker
      {:ok, _} = RosterApp.Orgs.assign_user_to_work_type(worker.id, work_type.id)
      {:ok, _} = RosterApp.Orgs.assign_user_to_department(worker.id, department.id)

      # Create initial shift with work type and department, already assigned to worker
      shift =
        shift_fixture(%{
          tenant_id: manager.tenant_id,
          work_type_id: work_type.id,
          department_id: department.id,
          assigned_user_id: worker.id
        })

      %{
        conn: conn,
        manager: manager,
        worker: worker,
        shift: shift,
        work_type: work_type,
        department: department
      }
    end

    test "shift creation is broadcast to all users in tenant", %{
      conn: conn,
      manager: manager,
      worker: worker,
      work_type: work_type,
      department: department
    } do
      # Connect as manager
      {:ok, manager_live, _html} = live(log_in_user(conn, manager), ~p"/shifts")

      # Connect as worker in a separate browser session
      {:ok, worker_live, _html} = live(log_in_user(conn, worker), ~p"/shifts")

      # Create new shift as manager
      assert manager_live |> element("a", "New Shift") |> render_click()
      assert_patch(manager_live, ~p"/shifts/new")

      new_shift_attrs =
        Map.merge(@create_attrs, %{
          work_type_id: work_type.id,
          department_id: department.id
        })

      assert manager_live
             |> form("#shift-form", shift: new_shift_attrs)
             |> render_submit()

      # Verify the shift appears in both views
      assert render(manager_live) =~ "some description"
      assert render(worker_live) =~ "some description"
    end

    test "shift update is broadcast to all users in tenant", %{
      conn: conn,
      manager: manager,
      worker: worker,
      shift: shift
    } do
      # Connect as manager
      {:ok, manager_live, _html} = live(log_in_user(conn, manager), ~p"/shifts")

      # Connect as worker in a separate browser session
      {:ok, worker_live, _html} = live(log_in_user(conn, worker), ~p"/shifts")

      # Update shift as manager
      assert manager_live
             |> element("#shifts-#{shift.id} a", "Edit")
             |> render_click()

      assert manager_live
             |> form("#shift-form", shift: @update_attrs)
             |> render_submit()

      # Verify the update appears in both views
      assert render(manager_live) =~ "some updated description"
      assert render(worker_live) =~ "some updated description"
    end

    test "shift deletion is broadcast to all users in tenant", %{
      conn: conn,
      manager: manager,
      worker: worker,
      shift: shift
    } do
      # Connect as manager
      {:ok, manager_live, _html} = live(log_in_user(conn, manager), ~p"/shifts")

      # Connect as worker in a separate browser session
      {:ok, worker_live, _html} = live(log_in_user(conn, worker), ~p"/shifts")

      # Delete shift as manager
      assert manager_live
             |> element("#shifts-#{shift.id} a", "Delete")
             |> render_click()

      # Verify the shift is removed from both views
      refute has_element?(manager_live, "#shifts-#{shift.id}")
      refute has_element?(worker_live, "#shifts-#{shift.id}")
    end

    test "shift assignment notification is sent to assigned user", %{
      conn: conn,
      manager: manager,
      worker: worker,
      shift: shift,
      work_type: work_type,
      department: department
    } do
      # Connect as manager
      {:ok, manager_live, _html} = live(log_in_user(conn, manager), ~p"/shifts")

      # Connect as worker in a separate browser session
      {:ok, worker_live, _html} = live(log_in_user(conn, worker), ~p"/shifts")

      # Verify initial assignment is visible
      assert render(manager_live) =~ worker.email
      assert render(worker_live) =~ worker.email

      # Update the shift
      assert manager_live
             |> element("#shifts-#{shift.id} a", "Edit")
             |> render_click()

      update_attrs =
        Map.merge(@update_attrs, %{
          assigned_user_id: worker.id,
          work_type_id: work_type.id,
          department_id: department.id
        })

      assert manager_live
             |> form("#shift-form", shift: update_attrs)
             |> render_submit()

      # Verify the update appears in both views
      assert render(manager_live) =~ worker.email
      assert render(worker_live) =~ worker.email
    end
  end

  describe "Show" do
    setup %{conn: conn} do
      user = user_fixture(%{role: "manager"})
      shift = shift_fixture()
      %{conn: log_in_user(conn, user), user: user, shift: shift}
    end

    test "displays shift", %{conn: conn, shift: shift} do
      {:ok, _show_live, html} = live(conn, ~p"/shifts/#{shift}")

      assert html =~ "Show Shift"
      assert html =~ shift.description
    end

    test "updates shift within modal", %{conn: conn, shift: shift} do
      {:ok, show_live, _html} = live(conn, ~p"/shifts/#{shift}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Shift"

      assert_patch(show_live, ~p"/shifts/#{shift}/show/edit")

      assert show_live
             |> form("#shift-form", shift: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/shifts/#{shift}")

      html = render(show_live)
      assert html =~ "Shift updated successfully"
      assert html =~ "some updated description"
    end
  end
end
