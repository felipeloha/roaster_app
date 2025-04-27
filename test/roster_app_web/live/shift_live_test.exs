defmodule RosterAppWeb.ShiftLiveTest do
  use RosterAppWeb.ConnCase

  import Phoenix.LiveViewTest
  import RosterApp.ShiftsFixtures
  import RosterApp.AccountsFixtures

  @create_attrs %{
    description: "some description",
    start_time: "2025-04-26T06:12:00Z",
    end_time: "2025-04-26T06:12:00Z"
  }
  @update_attrs %{
    description: "some updated description",
    start_time: "2025-04-27T06:12:00Z",
    end_time: "2025-04-27T06:12:00Z"
  }
  @invalid_attrs %{description: nil, start_time: nil, end_time: nil}

  def log_in_user_test(conn, user) do
    token = RosterApp.Accounts.generate_user_session_token(user)

    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:user_token, token)
  end

  describe "Index" do
    setup %{conn: conn} do
      user = user_fixture(%{role: "manager"})
      shift = shift_fixture()
      %{conn: log_in_user_test(conn, user), user: user, shift: shift}
    end

    test "lists all shifts", %{conn: conn, shift: shift} do
      {:ok, _index_live, html} = live(conn, ~p"/shifts")

      assert html =~ "Listing Shifts"
      assert html =~ shift.description
    end

    test "saves new shift", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/shifts")

      assert index_live |> element("a", "New Shift") |> render_click() =~
               "New Shift"

      assert_patch(index_live, ~p"/shifts/new")

      assert index_live
             |> form("#shift-form", shift: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#shift-form", shift: @create_attrs)
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

  describe "Show" do
    setup %{conn: conn} do
      user = user_fixture(%{role: "manager"})
      shift = shift_fixture()
      %{conn: log_in_user_test(conn, user), user: user, shift: shift}
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
             |> form("#shift-form", shift: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

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
