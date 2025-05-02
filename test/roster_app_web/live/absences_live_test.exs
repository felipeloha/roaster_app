defmodule RosterAppWeb.AbsencesLiveTest do
  use RosterAppWeb.ConnCase

  import Phoenix.LiveViewTest
  import RosterApp.OrgsFixtures
  import RosterApp.AccountsFixtures

  @create_attrs %{"unavailable_days" => [1, 2]}
  @update_attrs %{"unavailable_days" => [1]}

  describe "Index" do
    setup %{conn: conn} do
      user = user_fixture(%{role: "manager"})
      absences = absences_fixture(%{user_id: user.id})
      %{conn: log_in_user(conn, user), user: user, absences: absences}
    end

    test "lists all absences", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/absences")

      assert html =~ "Listing Absences"
    end

    test "saves new absences", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/absences")

      assert index_live |> element("a", "New Absences") |> render_click() =~
               "New Absences"

      assert_patch(index_live, ~p"/absences/new")

      assert index_live
             |> form("#absences-form", absences: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/absences")

      html = render(index_live)
      assert html =~ "Absences created successfully"
    end

    test "updates absences in listing", %{conn: conn, absences: absences} do
      {:ok, index_live, _html} = live(conn, ~p"/absences")

      assert index_live
             |> element("#absences_collection-#{absences.id} a", "Edit")
             |> render_click() =~
               "Edit Absences"

      assert_patch(index_live, ~p"/absences/#{absences}/edit")

      assert index_live
             |> form("#absences-form", absences: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/absences")

      html = render(index_live)
      assert html =~ "Absences updated successfully"
    end

    test "deletes absences in listing", %{conn: conn, absences: absences} do
      {:ok, index_live, _html} = live(conn, ~p"/absences")

      assert index_live
             |> element("#absences_collection-#{absences.id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#absences_collection-#{absences.id}")
    end
  end

  describe "Show" do
    # setup [:create_absences]
    setup %{conn: conn} do
      user = user_fixture(%{role: "manager"})
      absences = absences_fixture()
      %{conn: log_in_user(conn, user), user: user, absences: absences}
    end

    test "displays absences", %{conn: conn, absences: absences} do
      {:ok, _show_live, html} = live(conn, ~p"/absences/#{absences}")

      assert html =~ "Show Absences"
    end

    test "updates absences within modal", %{conn: conn, absences: absences} do
      {:ok, show_live, _html} = live(conn, ~p"/absences/#{absences}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Absences"

      assert_patch(show_live, ~p"/absences/#{absences}/show/edit")

      assert show_live
             |> form("#absences-form", absences: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/absences/#{absences}")

      html = render(show_live)
      assert html =~ "Absences updated successfully"
    end
  end
end
